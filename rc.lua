-- Standard awesome library
awful = require("awful")
require("awful.autofocus")
rules = require("awful.rules")
-- Theme handling library
beautiful = require("beautiful")
-- Notification library
naughty = require("naughty")
vicious = require("vicious")
wibox = require("wibox")
gears = require("gears")
mpdstatus = require("mpdstatus")
-- FIXME:
--require("inotify")
firerule_widget = require('firerule_widget')

net_widgets = require("net_widgets")

commandviewer = require("commandviewer")
mpc = require("mpc")
autorun = require("autorun")
--pinger = require("pinger")

-- {{{ parameters
if not pcall(function() parameters = require("parameters") end) then
    parameters = {
        mpd = {host = "localhost", port = "6600", fmt="%artist% - %album% - %title% (%date%)"},
        autorun_apps = {},
        autorestart_apps = {},
        terminal_sessions = {},
        mailboxes = {},
        interfaces = {'wlan0'}
    }
end
mpd = parameters.mpd
-- }}}

mpc.configure(mpd.host, mpd.port)

-- {{{ Variable definitions
-- Themes define colours, icons, and wallpapers
beautiful.init(awful.util.getdir("config") .. "/themes/zenburnm/theme.lua")
gears.wallpaper.set(gears.color.create_solid_pattern(gears.color.parse_color("#000000")))

-- This is used later as the default terminal and editor to run.
terminal = "urxvt"
editor = os.getenv("EDITOR") or "nano"
editor_cmd = terminal .. " -e " .. editor

color_red = "DarkSalmon"
color_green = "LimeGreen"
color_blue = "LightBlue"

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
layouts =
{
    awful.layout.suit.tile,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.top,
    awful.layout.suit.fair,
    awful.layout.suit.fair.horizontal,
    awful.layout.suit.spiral,
    awful.layout.suit.spiral.dwindle,
    awful.layout.suit.max,
--    awful.layout.suit.max.fullscreen,
    awful.layout.suit.magnifier,
    awful.layout.suit.floating,
}
-- }}}

-- {{{ Tags
-- Define a tag table which hold all screen tags.
tags = {}
for s = 1, screen.count() do
    -- Each screen has its own tag table.
    if s == 1 then
        tags[s] = awful.tag({ 1, 2, 3, 4, 5, 6, 7, 8, 9 }, s,
            {layouts[1], layouts[1], layouts[1], layouts[1], awful.layout.suit.fair, layouts[1], 
            layouts[1], layouts[1], awful.layout.suit.floating})
    else
        tags[s] = awful.tag({ 1, 2, 3, 4}, s,
            {awful.layout.suit.fair, layouts[1], layouts[1], awful.layout.suit.floating})
    end
end

-- TODO: use tag names?
app_tags = {
    im = tags[1][1],
    mc = tags[1][2],
    dev = tags[1][7],
    news = tags[1][5]
}
if screen.count() == 1 then
    app_tags.web = tags[1][3]
    app_tags.read = tags[1][4]
else
    app_tags.web = tags[2][3]
    app_tags.read = tags[2][2]
end
-- }}}

-- {{{ Menu
-- Create a laucher widget and a main menu
myawesomemenu = {
   { "manual", terminal .. " -e man awesome" },
   { "edit config", editor_cmd .. " " .. awful.util.getdir("config") .. "/rc.lua" },
   { "restart", awesome.restart },
   { "quit", awesome.quit }
}

mymainmenu = awful.menu({ items = { { "awesome", myawesomemenu, beautiful.awesome_icon },
                                    { "open terminal", terminal }
                                  }
                        })

mylauncher = awful.widget.launcher({ image = beautiful.awesome_icon,
                                     menu = mymainmenu })
-- }}}

-- {{{ Wibox
-- Create a textclock widget
separator = wibox.widget.textbox()
separator:set_text("::")

mytextclock = wibox.widget.textclock()

-- Create a systray
mysystray = wibox.widget.systray()

-- Date
datewidget = wibox.widget.textbox()
vicious.register(datewidget, vicious.widgets.date, "%b %d, %H:%M:%S", 1)

-- Memory
memwidget = wibox.widget.textbox()
memwidget:set_align("center")
vicious.register(memwidget, vicious.widgets.mem, "$2MB($1%):$6MB($5%)", 3)

-- CPU
-- cpuwidget = awful.widget.graph()
-- cpuwidget:set_width(30)
-- cpuwidget:set_background_color("#494B4F")
-- cpuwidget:set_color("#FF5656")
-- cpuwidget:set_gradient_colors({ "#FF5656", "#88A175", "#AECF96" })
cpuwidget = wibox.widget.textbox()
cpuwidget:set_align("center")
vicious.register(cpuwidget, vicious.widgets.cpu,
    function(widget, args)
        return string.format(
            "<span color='%s'>%3s%%</span>",
            color_blue, args[1])
    end, 3)

-- Network
netwidget = wibox.widget.textbox()
function interface_up(iface)
    local f = io.open("/sys/class/net/" .. iface .. "/operstate")
    if f ~= nil then
        local state = f:read("*all")
        f:close()
        return state == "up\n"
    end
    return false
end
vicious.register(netwidget, vicious.widgets.net,
    function(widget, args)
        local result = {}
        for i, iface in ipairs(parameters.interfaces) do
            --check existence of the interface by one value
            if interface_up(iface) and args['{'..iface..' down_kb}'] then
                table.insert(result, string.format(
                    '%s <span color="%s">%7s\226\134\147kB/s</span>:<span color="%s">%7s\226\134\145kB/s</span>',
                iface, color_red,
                args['{'..iface..' down_kb}'],
                color_green,
                args['{'..iface..' up_kb}']
                ))
            end
        end
        return table.concat(result, ':')
    end, 3)

-- FS
function range_sel(border, num, bigeq, less)
    return num >= border and bigeq or less
end

fswidget = wibox.widget.textbox()
vicious.cache(vicious.widgets.fs)
vicious.register(fswidget, vicious.widgets.fs,
        function(widget, args)
            local border = 5000
            local res = {}

            table.insert(res, "/ <span color=\"")
            table.insert(res, range_sel(border,tonumber(args["{/ avail_mb}"]),
                color_green, color_red))
            table.insert(res, "\">")
            table.insert(res, args["{/ avail_mb}"])
            table.insert(res,  "M</span>")

            if(args["{/home avail_mb}"]) then
                table.insert(res, ":/home <span color=\"")
                table.insert(res, range_sel(border,tonumber(args["{/home avail_mb}"]),
                    color_green, color_red))
                table.insert(res, "\">")
                table.insert(res, args["{/home avail_mb}"])
                table.insert(res, "M</span>")
            end

            if(args["{/media/sdb1 avail_mb}"]) then
                table.insert(res, ":/media/sdb1 <span color=\"")
                table.insert(res, range_sel(border,tonumber(args["{/media/sdb1 avail_mb}"]),
                    color_green, color_red))
                table.insert(res, "\">")
                table.insert(res, args["{/media/sdb1 avail_mb}"])
                table.insert(res, "M</span>")
            end

            return table.concat(res)
        end, 19)

-- disk io
diowidget = wibox.widget.textbox()
vicious.register(diowidget, vicious.widgets.dio,
    function(widget, args)
        write_kb = args['{sda write_kb}']
        return string.format('sda %7s\226\134\147kB:<span color="%s">%7s</span>\226\134\145kB',
            args['{sda read_kb}'],
            tonumber(write_kb) > 0 and color_red or theme.fg_normal,
            write_kb)
    end, 3)

-- thermal
thermwidget = wibox.widget.textbox()
thermwidget:set_align("center")
vicious.register(thermwidget, vicious.widgets.thermal, "$1C", 5, {"thermal_zone0", "sys"})

-- wifi
wifiwidget = wibox.widget.textbox()
vicious.register(wifiwidget, vicious.widgets.wifi, "${ssid}", 11, "wlan0")

mdirwidget = wibox.widget.textbox()
vicious.register(mdirwidget, vicious.widgets.mdir, " $1\226\156\137 ", 17, parameters.mailboxes)

-- mpd
mpdwidget = wibox.widget.textbox()
vicious.register(mpdwidget, vicious.widgets.mpd,
    function(widget, args)
        if args["{state}"] ~= "Stop" then
            return args["{Artist}"]..' - '.. args["{Title}"]
        else
            return "Stopped"
        end
    end, 3, {nil, mpd.host, mpd.port})

uptimewidget = wibox.widget.textbox()
uptimewidget:set_align("center")
vicious.register(uptimewidget, vicious.widgets.uptime,
    function(widget, args)
        return string.format(
            "%.2f,%.2f,%.2f",
            args[4], args[5], args[6])
    end, 61)

batwidget = wibox.widget.textbox()
batwidget:set_align("center")
vicious.register(batwidget, vicious.widgets.bat, '<span color="' .. color_red .. '">$2%</span>$1($3)', 7, "BAT0")

cpuinfwidget = wibox.widget.textbox()
cpuinfwidget:set_align("center")
vicious.register(cpuinfwidget, vicious.widgets.cpuinf,
    function(widget, args)
        return string.format(
            "%4sMHz", args["{cpu0 mhz}"])
    end, 5);

weatherwidget = wibox.widget.textbox()
weatherwidget:set_align("left")
--vicious.register(weatherwidget, vicious.widgets.weather,
--        function(widget, args)
--            local res = {}
--            --always add even "N/A" to hold the place
--            table.insert(res, args["{city}"])
--
--            --with the assumption that a value is never to be nil
--            local value = args["{tempc}"]
--            if(value ~= "N/A") then
--                table.insert(res, value .. "C")
--            end
--
--            value = args["{windkmh}"]
--            if(value ~= "N/A") then
--                table.insert(res, value .. "km/h")
--            end
--
--            return table.concat(res, " ")
--        end,
--        601, "UMMS")

volwidget = wibox.widget.textbox()
vicious.register(volwidget, vicious.widgets.volume, "$1$2", 2, "Master") 
function volume_down()
    awful.spawn("amixer set 'Master' 1dB-")
    vicious.force({volwidget,})
end
function volume_up()
    awful.spawn("amixer set 'Master' 1dB+")
    vicious.force({volwidget,})
end
function volume_toggle()
    awful.spawn("amixer set 'Master' toggle")
    vicious.force({volwidget,})
end

wanwidget = wibox.widget.textbox()
wanwidget:set_align("center")
-- don't use DNS to improve speed
-- google.com 
--pinger.register_pinger("74.125.232.20", 20,
--    function()
--        wanwidget.text = '<span color="'..color_green..'">@</span>'
--        naughty.notify{
--            text = 'internet connection is <span color="red">up</span>',
--            timeout = 5
--        }
--    end,
--    function()
--        wanwidget.text = '<span color="grey">@</span>'
--        naughty.notify{
--            text = 'internet connection is <span color="red">down</span>',
--            timeout = 5
--        }
--    end)

--deadlinewidget = widget({ type = "textbox" })
--deadlinewidget.align = "center"
--deadlinewidget.width = 80
--deadline = {}
--deadline.date = {year=2011, month=6, day=1, hour=0}
--deadline.make_str = function(date)
--        diff = os.time(date) - os.time()
--
--        if diff < 0 then
--            diff = 0
--        end
--
--        days = math.floor(diff/(3600*24))
--        hours = math.floor((diff - days*3600*24)/3600)
--        mins = math.floor((diff - days*3600*24 - hours*3600)/60)
--
--        return days .. "d:" .. hours .. "h:" .. mins .. "m"
--    end
--deadline.widget = deadlinewidget
--function register_deadline(deadline)
--    deadline.widget.text = deadline.make_str(deadline.date)
--    awful.hooks.timer.register(60, function()
--            deadline.widget.text = deadline.make_str(deadline.date)
--        end)
--end
--
--register_deadline(deadline)
frwidget = firerule_widget.create_widget()

-- Create a wibox for each screen and add it
mywibox = {}
bottomwibox = {}
mypromptbox = {}
mylayoutbox = {}
mytaglist = {}
mytaglist.buttons = awful.util.table.join(
                    awful.button({ }, 1, awful.tag.viewonly),
                    awful.button({ modkey }, 1, awful.client.movetotag),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, awful.client.toggletag),
                    awful.button({ }, 4, awful.tag.viewnext),
                    awful.button({ }, 5, awful.tag.viewprev)
                    )
mytasklist = {}
mytasklist.buttons = awful.util.table.join(
                     awful.button({ }, 1, function (c)
                                              if not c:isvisible() then
                                                  awful.tag.viewonly(c:tags()[1])
                                              end
                                              client.focus = c
                                              c:raise()
                                          end),
                     awful.button({ }, 3, function ()
                                              if instance then
                                                  instance:hide()
                                                  instance = nil
                                              else
                                                  instance = awful.menu.clients({ width=250 })
                                              end
                                          end),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                              if client.focus then client.focus:raise() end
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                              if client.focus then client.focus:raise() end
                                          end))

for s = 1, screen.count() do
    -- Create a promptbox for each screen
    mypromptbox[s] = awful.widget.prompt()
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    mylayoutbox[s] = awful.widget.layoutbox(s)
    mylayoutbox[s]:buttons(awful.util.table.join(
                           awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
                           awful.button({ }, 4, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)))
    -- Create a taglist widget
    mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.filter.all, mytaglist.buttons)

    -- Create a tasklist widget
    mytasklist[s] = awful.widget.tasklist(s, function(c)
                                              return awful.widget.tasklist.filter.currenttags(c, s)
                                          end, mytasklist.buttons)

    if s == 1 then
        -- Create the wibox
        mywibox[s] = awful.wibar({ position = "top", screen = s })
        bottomwibox[s] = awful.wibar({ position = "bottom", screen = s })
        -- Add widgets to the wibox - order matters
        toplayout = wibox.layout.align.horizontal()
        toprightlayout = wibox.layout.fixed.horizontal()
        toprightlayout:add(separator)
        toprightlayout:add(mpdwidget)
        toprightlayout:add(separator)
        toprightlayout:add(mdirwidget)
        toprightlayout:add(separator)
        toprightlayout:add(volwidget)
        toprightlayout:add(separator)
        toprightlayout:add(frwidget)
        toprightlayout:add(separator)
        if s == 1 then toprightlayout:add(mysystray) end
        toprightlayout:add(datewidget)
        toprightlayout:add(mylayoutbox[s])
        topleftlayout = wibox.layout.fixed.horizontal()
        topleftlayout:add(mytaglist[s])
        topleftlayout:add(mypromptbox[s])
        topmiddlelayout = wibox.layout.flex.horizontal()
        topmiddlelayout:add(mytasklist[s])
        toplayout:set_right(toprightlayout)
        toplayout:set_left(topleftlayout)
        toplayout:set_middle(topmiddlelayout)
        mywibox[s]:set_widget(toplayout)
        bottomlayout = wibox.layout.align.horizontal()
        bottomleftlayout = wibox.layout.fixed.horizontal()
        bottomleftlayout:add(separator)
        bottomleftlayout:add(cpuwidget)
        bottomleftlayout:add(separator)
        bottomleftlayout:add(uptimewidget)
        bottomleftlayout:add(separator)
        bottomleftlayout:add(wibox.container.constraint(memwidget, "min", 155)) 
        bottomleftlayout:add(separator)
        bottomrightlayout = wibox.layout.fixed.horizontal()
        bottomrightlayout:add(separator) 
        bottomrightlayout:add(fswidget) 
        bottomrightlayout:add(separator)
        bottomrightlayout:add(diowidget) 
        bottomrightlayout:add(separator)
        bottomrightlayout:add(wifiwidget)
        bottomrightlayout:add(separator)
        bottomrightlayout:add(netwidget) 
        bottomrightlayout:add(separator)
        bottomrightlayout:add(wibox.container.constraint(cpuinfwidget, "min", 55))
        bottomrightlayout:add(separator)
        bottomrightlayout:add(wibox.container.constraint(thermwidget, "min", 25))
        bottomrightlayout:add(separator)
        bottomrightlayout:add(wibox.container.constraint(batwidget, "min", 80))
        bottomrightlayout:add(separator)
        bottomlayout:set_left(bottomleftlayout)
        bottomlayout:set_right(bottomrightlayout)
        bottomwibox[s]:set_widget(bottomlayout)
    else
        mywibox[s] = awful.wibar({ position = "top", screen = s })
        toplayout = wibox.layout.align.horizontal()
        toprightlayout = wibox.layout.fixed.horizontal()
        toprightlayout:add(separator)
        toprightlayout:add(mpdwidget)
        toprightlayout:add(separator)
        toprightlayout:add(datewidget)
        toprightlayout:add(mylayoutbox[s])
        topleftlayout = wibox.layout.fixed.horizontal()
        topleftlayout:add(mytaglist[s])
        topleftlayout:add(mypromptbox[s])
        topmiddlelayout = wibox.layout.flex.horizontal()
        topmiddlelayout:add(mytasklist[s])
        toplayout:set_left(topleftlayout)
        toplayout:set_right(toprightlayout)
        toplayout:set_middle(topmiddlelayout)
        mywibox[s]:set_widget(toplayout)
    end
end
-- }}}

-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
globalkeys = awful.util.table.join(
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev       ),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext       ),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore),

    awful.key({ modkey,           }, "j",
        function ()
            awful.client.focus.byidx( 1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "k",
        function ()
            awful.client.focus.byidx(-1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "w", function () mymainmenu:show(true)        end),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end),
    awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end),
    awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end),

    -- Standard program
    awful.key({ modkey,           }, "Return", function () awful.spawn(terminal) end),
    awful.key({ modkey, "Control" }, "r", awesome.restart),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit),

    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)    end),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)    end),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1)      end),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1)      end),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1)         end),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1)         end),
    awful.key({ modkey,           }, "space", function () awful.layout.inc(layouts,  1) end),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(layouts, -1) end),

    -- Prompt
    awful.key({ modkey },            "r",     function () mypromptbox[awful.screen.focused().index]:run() end),

    awful.key({ modkey }, "x",
              function ()
                  awful.prompt.run({ prompt = "Run Lua code: " },
                  mypromptbox[awful.screen.focused().index].widget,
                  awful.util.eval, nil,
                  awful.util.getdir("cache") .. "/history_eval")
              end),

    awful.key({ "Mod1", "Control" }, "f", function () awful.spawn("firefox") end),
    awful.key({}, "XF86Launch1", function () awful.spawn("firefox") end),
    awful.key({ "Mod1", "Control" }, "l", function () awful.spawn("xscreensaver-command -lock") end),
    awful.key({}, "XF86ScreenSaver", function () awful.spawn("xscreensaver-command -lock") end),
    awful.key({ "Mod1", "Control" }, "v", function () awful.spawn("gvim") end),
    awful.key({}, "XF86Launch2", function () awful.spawn("gvim") end),

    -- Media
    awful.key({ "Mod1", "Control" }, "a", mpc.prev),
    awful.key({ "Mod1", "Control" }, "s", mpc.next),
    awful.key({ "Mod1", "Control" }, "x", mpc.toggle),
    awful.key({ "Mod1", "Control" }, "z", mpc.stop),
    awful.key({}, "XF86AudioStop", mpc.stop),
    awful.key({}, "XF86AudioPlay", mpc.toggle),
    awful.key({}, "XF86AudioNext", mpc.next),
    awful.key({}, "XF86AudioPrev", mpc.prev),
    awful.key({}, "XF86AudioLowerVolume", volume_down),
    awful.key({}, "XF86AudioRaiseVolume", volume_up),
    awful.key({}, "XF86AudioMute", volume_toggle),

    awful.key({ "Mod1", "Control" }, "m", function() commandviewer.view_command("mount") end),
    awful.key({ "Mod1", "Control" }, "n", function() commandviewer.view_command("netstat --inet --inet6 -pn") end),
    awful.key({ "Mod1", "Control" }, "d", function() mpdstatus.switch_mpd_status(mpc, parameters.mpd.fmt) end),
    awful.key({}, "XF86Battery", function() commandviewer.view_command("sensors") end)
)

clientkeys = awful.util.table.join(
    awful.key({ modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
    awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),
    awful.key({ modkey,           }, "o",      awful.client.movetoscreen                        ),
    awful.key({ modkey, "Shift"   }, "r",      function (c) c:redraw()                       end),
    awful.key({ modkey,           }, "n",      function (c) c.minimized = not c.minimized    end),
    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized = not c.maximized
        end)
)

-- Compute the maximum number of digit we need, limited to 9
keynumber = 0
for s = 1, screen.count() do
   keynumber = math.min(9, math.max(#tags[s], keynumber));
end

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, keynumber do
    globalkeys = awful.util.table.join(globalkeys,
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                      local screen = awful.screen.focused().index
                      if tags[screen][i] then
                          tags[screen][i]:view_only()
                      end
                  end),
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = awful.screen.focused().index
                      if tags[screen][i] then
                          awful.tag.viewtoggle(tags[screen][i])
                      end
                  end),
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      focused_client = client.focus
                      if focused_client and tags[focused_client.screen.index][i] then
                          focused_client:move_to_tag(tags[focused_client.screen.index][i])
                      end
                  end),
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      focused_client = client.focus
                      if focused_client and tags[focused_client.screen.index][i] then
                          focused_client:toggle_tag(tags[focused_client.screen.index][i])
                      end
                  end))
end

clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
rules.rules = {
    -- All clients will match this rule.
    { rule = {},
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = true,
                     keys = clientkeys,
                     buttons = clientbuttons,
                     screen = awful.screen.focused,
                 } },
    { rule = { class = "MPlayer" },
      properties = { floating = true } },
    { rule = { class = "mpv" },
      properties = { floating = true } },
    { rule = { class = "Pidgin", role = "conversation" },
      properties = { tag = app_tags.im } },
    { rule = { class = "Pidgin", role = "multifield" },
      properties = { tag = app_tags.im } },
    { rule = { class = "Pidgin", role = "buddy_list" },
      properties = {
          floating = true,
          maximized_vertical = true,
          placement = awful.placement.right,
      } },
    { rule = { class = "pinentry" },
      properties = { floating = true } },
    { rule = { class = "gimp" },
      properties = { floating = true } },
    { rule = { class = "etracer" },
      properties = { floating = true } },
    { rule = { class = "Skype" },
      properties = { floating = true } },
    { rule = { name = "glxgears" },
      properties = { floating = true } },
    { rule = { class = "Firefox", role="browser" },
      properties = { tag = app_tags.web } },
    { rule = { class = "chromium-browser-chromium" },
      properties = { tag = app_tags.web } },
    { rule = { class = "Evince" },
      properties = { tag = app_tags.read } },
    { rule = { class = "Zathura" },
      properties = { tag = app_tags.read } },
    { rule = { class = "fbreader" },
      properties = { tag = app_tags.read } },
    { rule = { name = "vim" },
      properties = { tag = app_tags.dev } },
    { rule = { name = "mc" },
      properties = { tag = app_tags.mc } },
    { rule = { name = "news" },
      properties = { tag = app_tags.news } },
    { rule = { name = "chat" },
      properties = { tag = app_tags.im } },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c, startup)
    -- Add a titlebar
    -- awful.titlebar.add(c, { modkey = modkey })

    if not startup then
        -- Set the windows at the slave,
        -- i.e. put it at the end of others instead of setting it master.
        -- awful.client.setslave(c)

        -- Put windows in a smart way, only if they does not set an initial position.
        if not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.no_overlap(c)
            awful.placement.no_offscreen(c)
        end
    end
end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}

autorun.run_apps(parameters.autorun_apps)
autorun.restart_apps(parameters.autorestart_apps)
autorun.run_sessions(parameters.terminal_sessions)
