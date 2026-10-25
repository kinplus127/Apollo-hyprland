#!/usr/bin/env bash
# Part 1: packages + small system/user config
# (hyprland.lua / hyprpm plugins come in a later part — not here)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USER_NAME="${SUDO_USER:-$USER}"
USER_HOME="$(getent passwd "$USER_NAME" | cut -d: -f6)"

need_root() {
  if [[ "$(id -u)" -ne 0 ]]; then
    echo "Run with sudo: sudo ./install.sh" >&2
    exit 1
  fi
}

aur_helper() {
  if command -v yay >/dev/null 2>&1; then
    echo yay
  else
    echo ""
  fi
}

# Bootstrap yay (yay-bin) if missing. Needs git + base-devel (makepkg).
ensure_yay() {
  if command -v yay >/dev/null 2>&1; then
    echo "==> yay already installed"
    return 0
  fi

  echo "==> bootstrap yay (yay-bin from AUR)"
  pacman -S --needed --noconfirm git base-devel

  local build_dir pkg
  # mktemp as the real user — root-owned /tmp/... causes git clone Permission denied
  build_dir="$(sudo -u "$USER_NAME" mktemp -d /tmp/yay-bin.XXXXXX)"

  # Clone + build as the real user (makepkg refuses root)
  sudo -u "$USER_NAME" git clone --depth 1     https://aur.archlinux.org/yay-bin.git "$build_dir/yay-bin"
  sudo -u "$USER_NAME" bash -c "cd '$build_dir/yay-bin' && makepkg -s --noconfirm"

  # Exclude *-debug-* — unsorted find can pick debug package first (no yay binary)
  pkg="$(find "$build_dir/yay-bin" -maxdepth 1 -name 'yay-bin-*.pkg.tar.*' ! -name '*-debug-*' | head -n1)"
  if [[ -z "$pkg" ]]; then
    rm -rf "$build_dir"
    echo "==> yay bootstrap failed (no package built)" >&2
    exit 1
  fi
  echo "==> installing $(basename "$pkg")"
  pacman -U --noconfirm "$pkg"
  rm -rf "$build_dir"
  hash -r 2>/dev/null || true

  if ! command -v yay >/dev/null 2>&1 && [[ ! -x /usr/bin/yay ]]; then
    echo "==> yay bootstrap failed (yay not on PATH after install)" >&2
    exit 1
  fi
  echo "==> yay ready: $(command -v yay 2>/dev/null || echo /usr/bin/yay)"
}

install_pacman() {
  local pkgs=(
    # Hyprland stack
    hyprland
    hyprlock
    hypridle
    hyprpolkitagent
    hyprpicker
    hyprland-qt-support
    hyprpm
    hyprshutdown
    hyprland-guiutils
    # Portals
    xdg-desktop-portal
    xdg-desktop-portal-hyprland
    xdg-desktop-portal-kde
    # Session
    greetd
    greetd-tuigreet
    # Apps / shell
    kitty
    neovim
    fish
    dolphin
    ark
    awww
    # Wayland / xdg helpers
    xorg-xwayland
    xdg-user-dirs
    xdg-utils
    qt5-wayland
    qt6-wayland
    qt6-svg
    qt6ct
    gsettings-desktop-schemas
    # HyprCapture / plugin build deps
    cmake
    nlohmann-json
    qt6-base
    layer-shell-qt
    pipewire
    libpipewire
    ffmpeg
    libpulse
    # Clipboard
    wl-clipboard
    cliphist
    wl-clip-persist
  )

  # quickshell: official repo if present, else AUR in install_aur
  if pacman -Si quickshell >/dev/null 2>&1; then
    pkgs+=(quickshell)
  fi

  echo "==> pacman packages"
  pacman -Syu --needed --noconfirm "${pkgs[@]}"
}

install_aur() {
  local helper
  helper="$(aur_helper)"
  local aur_pkgs=(brave-origin-bin)

  if ! pacman -Q quickshell >/dev/null 2>&1; then
    aur_pkgs+=(quickshell)
  fi

  if [[ ${#aur_pkgs[@]} -eq 0 ]]; then
    return 0
  fi

  if [[ -z "$helper" ]]; then
    echo "==> yay not found after bootstrap. Install AUR pkgs manually:"
    printf '    %s\n' "${aur_pkgs[@]}"
    return 0
  fi

  echo "==> AUR via $helper (as $USER_NAME): ${aur_pkgs[*]}"
  sudo -u "$USER_NAME" "$helper" -S --needed --noconfirm "${aur_pkgs[@]}"
}

configure_greetd() {
  echo "==> greetd + tuigreet → start-hyprland"
  install -d -m 755 /etc/greetd
  install -m 644 "$ROOT/config/greetd-config.toml" /etc/greetd/config.toml
  systemctl enable greetd.service
}

configure_portals() {
  local dest="$USER_HOME/.config/xdg-desktop-portal"
  echo "==> portals.conf → $dest (FileChooser=kde, default=hyprland)"
  install -d -m 755 -o "$USER_NAME" -g "$USER_NAME" "$dest"
  install -m 644 -o "$USER_NAME" -g "$USER_NAME" \
    "$ROOT/config/portals.conf" "$dest/portals.conf"
}

configure_xdg_dirs() {
  echo "==> xdg-user-dirs-update (as $USER_NAME)"
  sudo -u "$USER_NAME" xdg-user-dirs-update || true
}

install_fonts() {
  local src="$ROOT/fonts"
  local dest="$USER_HOME/.local/share/fonts/hyprland-setup"
  local count

  count="$(find "$src" -type f \( -iname '*.ttf' -o -iname '*.otf' -o -iname '*.ttc' \) 2>/dev/null | wc -l | tr -d ' ')"
  if [[ "$count" -eq 0 ]]; then
    echo "==> fonts: no .ttf/.otf/.ttc in $src — skip (see fonts/SOURCES.md)"
    return 0
  fi

  echo "==> fonts: sync $count file(s) → $dest (keep folder layout)"
  install -d -m 755 -o "$USER_NAME" -g "$USER_NAME" "$dest"
  # Preserve geist/, noto-*, nerd-symbols/ layout
  # Copy tree but only font files + dirs
  (
    cd "$src"
    find . -type f \( -iname '*.ttf' -o -iname '*.otf' -o -iname '*.ttc' \) -print0
  ) | while IFS= read -r -d '' rel; do
    rel="${rel#./}"
    install -d -m 755 -o "$USER_NAME" -g "$USER_NAME" "$dest/$(dirname "$rel")"
    install -m 644 -o "$USER_NAME" -g "$USER_NAME" "$src/$rel" "$dest/$rel"
  done
  sudo -u "$USER_NAME" fc-cache -fv "$dest"
}


install_toolkit_fonts() {
  echo "==> GTK / KDE font settings"
  local gtk3="$USER_HOME/.config/gtk-3.0"
  local gtk4="$USER_HOME/.config/gtk-4.0"
  install -d -m 755 -o "$USER_NAME" -g "$USER_NAME" "$gtk3" "$gtk4" "$USER_HOME/.config"
  install -m 644 -o "$USER_NAME" -g "$USER_NAME" \
    "$ROOT/config/gtk-3.0/settings.ini" "$gtk3/settings.ini"
  install -m 644 -o "$USER_NAME" -g "$USER_NAME" \
    "$ROOT/config/gtk-4.0/settings.ini" "$gtk4/settings.ini"
  install -m 644 -o "$USER_NAME" -g "$USER_NAME" \
    "$ROOT/config/kdeglobals" "$USER_HOME/.config/kdeglobals"
  # qt6ct only if package present
  if pacman -Q qt6ct >/dev/null 2>&1 || [[ -d /usr/share/qt6ct ]]; then
    install -d -m 755 -o "$USER_NAME" -g "$USER_NAME" "$USER_HOME/.config/qt6ct"
    install -m 644 -o "$USER_NAME" -g "$USER_NAME" \
      "$ROOT/config/qt6ct/qt6ct.conf" "$USER_HOME/.config/qt6ct/qt6ct.conf"
  fi
  echo "==> gsettings fonts (if available)"
  sudo -u "$USER_NAME" bash "$ROOT/scripts/apply-gsettings-fonts.sh" || true
}

install_fontconfig() {
  local dest="$USER_HOME/.config/fontconfig"
  local confd="$dest/conf.d"
  echo "==> fontconfig → $dest (Geist / Noto CJK HK / emoji / Nerd Symbols)"
  install -d -m 755 -o "$USER_NAME" -g "$USER_NAME" "$dest" "$confd"
  install -m 644 -o "$USER_NAME" -g "$USER_NAME" \
    "$ROOT/config/fontconfig/fonts.conf" "$dest/fonts.conf"
  install -m 644 -o "$USER_NAME" -g "$USER_NAME" \
    "$ROOT/config/fontconfig/10-nerd-font-symbols.conf" "$confd/10-nerd-font-symbols.conf"
  sudo -u "$USER_NAME" fc-cache -fv
}


install_hypr_config() {
  local dest="$USER_HOME/.config/hypr"
  echo "==> hypr config → $dest"
  install -d -m 755 -o "$USER_NAME" -g "$USER_NAME" "$dest/modules" "$dest/scripts"
  install -m 644 -o "$USER_NAME" -g "$USER_NAME" \
    "$ROOT/config/hypr/hyprland.lua" "$dest/hyprland.lua"
  install -m 644 -o "$USER_NAME" -g "$USER_NAME" \
    "$ROOT/config/hypr/hypridle.conf" "$dest/hypridle.conf"
  install -m 644 -o "$USER_NAME" -g "$USER_NAME" \
    "$ROOT/config/hypr/hyprlock.conf" "$dest/hyprlock.conf"
  local f
  for f in "$ROOT/config/hypr/modules/"*.lua; do
    install -m 644 -o "$USER_NAME" -g "$USER_NAME" "$f" "$dest/modules/"
  done
  install -m 755 -o "$USER_NAME" -g "$USER_NAME" \
    "$ROOT/scripts/set-wallpaper.sh" "$dest/scripts/set-wallpaper.sh"
}

# Exact copy only (no convert/resize). Mirrors Apollo's wallpaper install.
install_wallpapers() {
  local src="$ROOT/wallpapers"
  local dest="${XDG_PICTURES_DIR:-$USER_HOME/Pictures}/wallpapers"
  local count f

  if [[ ! -d "$src" ]]; then
    echo "==> wallpapers: no directory $src — skip"
    return 0
  fi

  count="$(find "$src" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) 2>/dev/null | wc -l | tr -d ' ')"
  if [[ "$count" -eq 0 ]]; then
    echo "==> wallpapers: no jpg/jpeg/png/webp in $src — skip"
    return 0
  fi

  echo "==> wallpapers: install $count file(s) → $dest (exact copy)"
  install -d -m 755 -o "$USER_NAME" -g "$USER_NAME" "$dest"
  while IFS= read -r -d '' f; do
    install -m 0644 -o "$USER_NAME" -g "$USER_NAME" "$f" "$dest/$(basename "$f")"
  done < <(find "$src" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) -print0)
}


fix_user_home_ownership() {
  # install -d / fc-cache under sudo can leave root-owned dirs fish cannot write
  echo "==> ensure $USER_NAME owns ~/.local and ~/.config"
  for d in "$USER_HOME/.local" "$USER_HOME/.config"; do
    [[ -e "$d" ]] || continue
    chown -R "$USER_NAME:$USER_NAME" "$d" || true
  done
}

set_fish_shell() {
  local fish_path
  fish_path="$(command -v fish)"
  if [[ -z "$fish_path" ]]; then
    echo "==> fish not on PATH — skip chsh"
    return 0
  fi
  if ! grep -qxF "$fish_path" /etc/shells 2>/dev/null; then
    echo "$fish_path" >> /etc/shells
  fi
  local current
  current="$(getent passwd "$USER_NAME" | cut -d: -f7)"
  if [[ "$current" == "$fish_path" ]]; then
    echo "==> login shell already fish"
    return 0
  fi
  echo "==> chsh $USER_NAME → fish"
  chsh -s "$fish_path" "$USER_NAME"
}

main() {
  need_root
  echo "Part 1 install — packages + small config"
  echo "Root: $ROOT | User: $USER_NAME ($USER_HOME)"
  echo

  install_pacman
  ensure_yay
  install_aur
  configure_greetd
  configure_portals
  configure_xdg_dirs
  install_fonts
  install_fontconfig
  install_toolkit_fonts
  install_hypr_config
  install_wallpapers
  set_fish_shell
  fix_user_home_ownership

  echo
  echo "Part 1 done."
  echo "hyprland.lua skeleton installed. Next (later): hyprpm plugins / your tweaks."
  echo "Reboot (or systemctl start greetd) then log in via tuigreet."
  echo "Note: LazyVim is not installed here — bootstrap nvim separately when you want."
}

main "$@"
