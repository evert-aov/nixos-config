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

GSETTINGS_BIN="$(command -v gsettings 2>/dev/null || echo "/run/current-system/sw/bin/gsettings")"
if [[ -x "$GSETTINGS_BIN" ]]; then
    schemas_dir="$(ls -d /run/current-system/sw/share/gsettings-schemas/gsettings-desktop-schemas* 2>/dev/null | head -n 1 || true)"
    if [[ -n "$schemas_dir" ]]; then
        export XDG_DATA_DIRS="$schemas_dir:${XDG_DATA_DIRS:-}"
    fi
    "$GSETTINGS_BIN" set org.gnome.desktop.interface color-scheme "$preference" || true
    "$GSETTINGS_BIN" set org.gnome.desktop.interface gtk-theme "$gtk_theme" || true
fi
