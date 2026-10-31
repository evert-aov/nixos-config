#!/usr/bin/env bash
set -euo pipefail
state_file="${XDG_CACHE_HOME:-$HOME/.cache}/quickshell/theme-mode"
[[ -f "$state_file" ]] || exit 0
read -r mode < "$state_file"
case "$mode" in
    light) preference=prefer-light; gtk_theme=adw-gtk3 ;;
    dark) preference=prefer-dark; gtk_theme=adw-gtk3-dark ;;
    *) exit 1 ;;
esac
gsettings set org.gnome.desktop.interface color-scheme "$preference"
gsettings set org.gnome.desktop.interface gtk-theme "$gtk_theme"
