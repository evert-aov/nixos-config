#!/usr/bin/env bash
set -euo pipefail

# Asegurar que el submapa vuelva a reset al salir
cleanup() {
    if [[ -n "${LISTENER_PID:-}" ]]; then
        kill "$LISTENER_PID" 2>/dev/null || true
    fi
    hyprctl dispatch 'hl.dsp.submap("reset")' >/dev/null 2>&1 || true
}
trap cleanup EXIT INT TERM

# Escuchar el socket IPC de Hyprland para alternar automáticamente al enfocar la ventana
SOC="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"

if [[ -S "$SOC" ]]; then
    (
        socat -u UNIX-CONNECT:"$SOC" STDOUT 2>/dev/null | while read -r line; do
            case "$line" in
                activewindow\>\>win11*|activewindow\>\>xfreerdp*|activewindow\>\>FreeRDP*)
                    hyprctl dispatch 'hl.dsp.submap("passthru")' >/dev/null 2>&1
                    ;;
                activewindow\>\>*)
                    hyprctl dispatch 'hl.dsp.submap("reset")' >/dev/null 2>&1
                    ;;
            esac
        done
    ) &
    LISTENER_PID=$!
fi

# Lanzar FreeRDP
if command -v xfreerdp >/dev/null 2>&1; then
    xfreerdp /v:127.0.0.1:3389 /u:evert /p:nakroth /cert:ignore /dynamic-resolution +clipboard /sound /wm-class:win11 /t:"Windows 11"
else
    nix-shell -p freerdp --run "xfreerdp /v:127.0.0.1:3389 /u:evert /p:nakroth /cert:ignore /dynamic-resolution +clipboard /sound /wm-class:win11 /t:'Windows 11'"
fi
