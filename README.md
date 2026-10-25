# Apollo-hyprland

Arch Linux Hyprland (Lua config, ≥0.55) install + setup draft.

## Quick start

```bash
sudo ./install.sh
# After first Hyprland login (hyprpm needs a session):
./scripts/install-plugins.sh
```

## Layout

- `install.sh` — packages (pacman + yay bootstrap), greetd/tuigreet, portals, fonts, toolkit fonts, hypr config, fish as login shell
- `config/hypr/` — modular `hyprland.lua` + hypridle/hyprlock
- `scripts/` — hyprpm plugins, gsettings fonts
- `fonts/` — font files (see `fonts/SOURCES.md`); install copies them into `~/.local/share/fonts/hyprland-setup`

## Notes

- Not a fork of [Apollo](https://github.com/kinplus127/Apollo); new Hyprland stack.
- LazyVim / NVIDIA optional blocks are left for later.
