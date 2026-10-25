#!/usr/bin/env bash
# Pick one image from ~/Pictures/wallpapers and set it with awww.
# awww-daemon is started separately. Failure must not abort the session.
warn() { echo "warning: $*" >&2; }

if ! command -v awww >/dev/null 2>&1; then
  warn "awww not found; skipping wallpaper"
  exit 0
fi

dir="${XDG_PICTURES_DIR:-$HOME/Pictures}/wallpapers"
if [[ ! -d "$dir" ]]; then
  warn "wallpaper directory missing ($dir); skipping"
  exit 0
fi

images=()
while IFS= read -r -d '' f; do
  images+=("$f")
done < <(find "$dir" -maxdepth 1 -type f \
  \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.gif' -o -iname '*.bmp' \) \
  -print0 2>/dev/null || true)

if [[ ${#images[@]} -eq 0 ]]; then
  warn "no wallpapers in $dir; skipping"
  exit 0
fi

picked="${images[$((RANDOM % ${#images[@]}))]}"

ready=0
for _ in {1..25}; do
  if awww query >/dev/null 2>&1; then
    ready=1
    break
  fi
  sleep 0.2
done

if [[ "$ready" -ne 1 ]]; then
  warn "awww-daemon not ready; skipping wallpaper"
  exit 0
fi

awww img "$picked" || warn "awww img failed for $picked"
exit 0
