#!/usr/bin/env bash
# Apply GNOME/GTK interface font via gsettings (if available).
set -euo pipefail
if ! command -v gsettings >/dev/null 2>&1; then
  echo "gsettings not found — skip (install gsettings-desktop-schemas if you want this)"
  exit 0
fi
gsettings set org.gnome.desktop.interface font-name 'Geist 11' || true
gsettings set org.gnome.desktop.interface document-font-name 'Geist 11' || true
gsettings set org.gnome.desktop.interface monospace-font-name 'Geist Mono 11' || true
echo "gsettings fonts applied"
