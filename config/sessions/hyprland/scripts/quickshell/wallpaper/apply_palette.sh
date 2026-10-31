#!/usr/bin/env bash
set -euo pipefail

image="$1"
shift
# Measure average RGB chroma: HSL saturation exaggerates near-white beige.
chroma=$(magick "$image" -resize '64x64!' -colorspace sRGB \
    -fx 'max(r,max(g,b))-min(r,min(g,b))' -format '%[fx:mean]' info:)
scheme=scheme-tonal-spot
if awk -v chroma="$chroma" 'BEGIN { exit !(chroma < 0.10) }'; then
    scheme=scheme-neutral
fi
brightness=$(magick "$image" -resize '64x64!' -colorspace Gray -format '%[fx:mean]' info:)
mode=dark
if awk -v brightness="$brightness" 'BEGIN { exit !(brightness >= 0.55) }'; then
    mode=light
fi
matugen image --source-color-index 0 --type "$scheme" --mode "$mode" "$image" "$@"
# Dry runs must not change the desktop preference.
for argument in "$@"; do
    [[ "$argument" == --dry-run ]] && exit 0
done
state_dir="${XDG_CACHE_HOME:-$HOME/.cache}/quickshell"
mkdir -p "$state_dir"
printf '%s\n' "$mode" > "$state_dir/theme-mode.new"
mv -f "$state_dir/theme-mode.new" "$state_dir/theme-mode"
bash "$(dirname "${BASH_SOURCE[0]}")/sync_theme_mode.sh"
