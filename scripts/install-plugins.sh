#!/usr/bin/env bash
# Run once inside a Hyprland session (as your user, not root).
# Builds/enables: hyprbars, hyprcapture, Hyprspace
set -euo pipefail

hyprpm update
hyprpm add https://github.com/hyprwm/hyprland-plugins
hyprpm enable hyprbars

hyprpm add https://github.com/gfhdhytghd/HyprCapture
hyprpm enable hyprcapture

hyprpm add https://github.com/KZDKM/Hyprspace
hyprpm enable Hyprspace

hyprpm reload
echo "Plugins enabled. Check: hyprctl plugin list"
