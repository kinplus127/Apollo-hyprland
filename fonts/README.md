# Fonts (files in-repo, not pacman)

See `SOURCES.md` for upstream links. `install.sh` copies these into
`~/.local/share/fonts/hyprland-setup/` and installs `config/fontconfig/fonts.conf`
so sans / mono / emoji resolve system-wide via fontconfig.

Verify after install:

```bash
fc-match sans-serif
fc-match monospace
fc-match "Noto Sans CJK HK"
fc-match emoji
```
