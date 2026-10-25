#!/usr/bin/env bash
# Run once inside a Hyprland session (as your user, not root).
# Builds/enables: hyprbars, hyprcapture, Hyprspace
set -euo pipefail

CFG="${XDG_CONFIG_HOME:-$HOME/.config}/hypr"
MARKER="$CFG/.plugins-enabled"

hyprpm update
hyprpm add https://github.com/hyprwm/hyprland-plugins
hyprpm enable hyprbars

hyprpm add https://github.com/gfhdhytghd/HyprCapture
hyprpm enable hyprcapture

hyprpm add https://github.com/KZDKM/Hyprspace
hyprpm enable Hyprspace

mkdir -p "$CFG"
touch "$MARKER"

hyprpm reload
hyprctl reload || true
echo "Plugins enabled (marker: $MARKER). Check: hyprctl plugin list"
echo "Super+C / Super+Shift+C / Super+Tab now active after reload."
