-- Plugin options (after hyprpm enable + reload)
-- HyprCapture / hyprbars / Hyprspace
-- Unknown plugin.* keys error until plugins are installed — gated by marker
-- created by scripts/install-plugins.sh

-- Allow hyprpm to load plugins when permissions are enforced
hl.permission("/usr/(bin|local/bin)/hyprpm", "plugin", "allow")

local home = os.getenv("HOME") or ""
local marker = home .. "/.config/hypr/.plugins-enabled"
local enabled = false
do
    local f = io.open(marker, "r")
    if f then
        f:close()
        enabled = true
    end
end

if not enabled then
    return
end

hl.config({
    plugin = {
        hyprbars = {
            bar_height = 28,
            bar_title_enabled = true,
            bar_text_size = 11,
            bar_text_font = "Geist",
            bar_buttons_alignment = "right",
            bar_part_of_window = true,
            on_double_click = [[hyprctl dispatch 'hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" })']],
        },
        overview = {
            -- Hyprspace
            onBottom = false,
            autoDrag = true,
        },
    },
})

pcall(function()
    hl.plugin.hyprbars.add_button({
        bg_color = "rgb(ff4040)",
        fg_color = "rgb(ffffff)",
        size = 12,
        icon = "✕",
        action = [[hyprctl dispatch 'hl.dsp.window.close()']],
    })
    hl.plugin.hyprbars.add_button({
        bg_color = "rgb(eeee11)",
        fg_color = "rgb(000000)",
        size = 12,
        icon = "□",
        action = [[hyprctl dispatch 'hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" })']],
    })
    hl.plugin.hyprbars.add_button({
        bg_color = "rgb(4040ff)",
        fg_color = "rgb(ffffff)",
        size = 12,
        icon = "—",
        action = [[hyprctl dispatch 'hl.dsp.window.float({ action = "toggle" })']],
    })
end)
