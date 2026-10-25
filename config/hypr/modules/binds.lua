-- Hyprland require() scopes are isolated — pull programs via return table
local P = require("modules.programs")
local mainMod = "SUPER"

-- Core (your map)
hl.bind(mainMod .. " + Q", hl.dsp.window.kill())
hl.bind(mainMod .. " + W", hl.dsp.window.close())
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(P.terminal))
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("hyprlock"))
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))

-- QS launcher (wire IPC / command when ready)
-- hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("TODO-qs-launcher"))

-- HyprCapture / Hyprspace — only after scripts/install-plugins.sh
local plugins_on = false
do
    local f = io.open((os.getenv("HOME") or "") .. "/.config/hypr/.plugins-enabled", "r")
    if f then f:close(); plugins_on = true end
end
if plugins_on then
    hl.bind(mainMod .. " + C", function()
        hl.plugin.hyprcapture.open("region")
    end)
    hl.bind(mainMod .. " + SHIFT + C", function()
        hl.plugin.hyprcapture.open("fullscreen")
    end)
    hl.bind(mainMod .. " + TAB", function()
        hl.plugin.overview.toggle()
    end)
end

hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(P.fileManager))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))

hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true })
