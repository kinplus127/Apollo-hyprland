#!/usr/bin/env bash
# Run once inside a Hyprland session (as your user, not root).
# Builds/enables: hyprbars, hyprcapture (optional), Hyprspace
set -euo pipefail

CFG="${XDG_CONFIG_HOME:-$HOME/.config}/hypr"
MARKER="$CFG/.plugins-enabled"

hyprpm update

echo "==> hyprland-plugins (hyprbars)"
hyprpm add https://github.com/hyprwm/hyprland-plugins || true
hyprpm enable hyprbars

echo "==> Hyprspace"
hyprpm add https://github.com/KZDKM/Hyprspace || true
hyprpm enable Hyprspace

echo "==> HyprCapture (needs cmake/qt6/layer-shell-qt/pipewire/ffmpeg — may fail)"
set +e
hyprpm add https://github.com/gfhdhytghd/HyprCapture
hyprpm enable hyprcapture
capture_ok=$?
set -e
if [[ "$capture_ok" -ne 0 ]]; then
  echo "==> HyprCapture skipped (build/enable failed). Super+C binds stay inactive until it works."
  echo "    Try: sudo pacman -S --needed cmake nlohmann-json qt6-base qt6-wayland layer-shell-qt pipewire libpipewire ffmpeg libpulse"
  echo "    Then: hyprpm add https://github.com/gfhdhytghd/HyprCapture && hyprpm enable hyprcapture && hyprpm reload"
fi

mkdir -p "$CFG"
# Marker enables hyprbars/Hyprspace config even if capture failed
touch "$MARKER"

hyprpm reload
hyprctl reload || true
echo "Plugins step done (marker: $MARKER). Check: hyprctl plugin list"
