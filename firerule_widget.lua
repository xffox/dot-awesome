wibox = require("wibox")
if not pcall(function() firerule = require('firerule') end) then
    firerule = nil
end

function format_text(firewall)
    if firewall == 'home.fr' then
        return '\226\140\130'
    elseif firewall == 'paranoid.fr' then
        return '\226\152\160'
    else
        return '?'
    end
end

function create_widget()
    if not firerule then return nil end
    local widget = wibox.widget.textbox()
    local frmon = firerule.FireruleMonitor:new()
    widget.text = format_text(frmon:get_firewall())
    frmon:on_firewall_changed(function(firewall)
        widget.text = format_text(firewall)
    end)
    return widget
end

return {
    create_widget = create_widget
}
