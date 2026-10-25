#!/usr/bin/env bash
# Run once inside a Hyprland session (as your user, not root).
# Builds/enables: hyprbars, hyprcapture (optional), Hyprspace
set -euo pipefail

CFG="${XDG_CONFIG_HOME:-$HOME/.config}/hypr"
MARKER="$CFG/.plugins-enabled"
# binds.lua reads ~/.config/hypr/.hyprcapture-enabled, not $XDG_CONFIG_HOME.
CAPTURE_MARKER="$HOME/.config/hypr/.hyprcapture-enabled"

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

mkdir -p "$CFG" "$(dirname "$CAPTURE_MARKER")"
# Super+C only. `hyprpm enable` can return 0 when the plugin failed to build,
# so also reject the "failed to build" state. Drop a stale marker on failure
# so an old bind does not stay active. `hyprpm add` exiting 1 (repo already
# installed) is fine when enable succeeds.
if [[ "$capture_ok" -eq 0 ]] && ! hyprpm list 2>/dev/null | grep -F 'hyprcapture' -A1 | grep -q 'failed to build'; then
  touch "$CAPTURE_MARKER"
else
  rm -f "$CAPTURE_MARKER"
  echo "==> HyprCapture skipped (build/enable failed). Super+C stays inactive until capture works."
  echo "    Try: sudo pacman -S --needed base-devel cmake git cpio nlohmann-json lua glib2 qt6-base qt6-svg qt6-wayland layer-shell-qt opencv pipewire libpipewire fftw libpulse ffmpeg wl-clipboard"
  echo "    Then: hyprpm add https://github.com/gfhdhytghd/HyprCapture && hyprpm enable hyprcapture && hyprpm reload"
fi

# Marker enables hyprbars/Hyprspace config even if capture failed
touch "$MARKER"

hyprpm reload
hyprctl reload || true
echo "Plugins step done (marker: $MARKER). Check: hyprctl plugin list"
