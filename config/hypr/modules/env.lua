-- Environment (set before display server init)
-- Wiki: https://wiki.hypr.land/configuring/core/environment-variables/
-- Do NOT put these in /etc/environment (breaks X11 sessions).

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("SDL_VIDEODRIVER", "wayland")
hl.env("CLUTTER_BACKEND", "wayland")

hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")

hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- Optional NVIDIA (uncomment if using proprietary drivers)
-- https://wiki.hypr.land/Nvidia/
-- hl.env("LIBVA_DRIVER_NAME", "nvidia")
-- hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
-- hl.env("NVD_BACKEND", "direct")
-- hl.env("GBM_BACKEND", "nvidia-drm")
