#!/usr/bin/env bash

RUN_DIR="${XDG_RUNTIME_DIR:-/tmp}/quickshell/coffee"
STATE_FILE="$RUN_DIR/active"
PID_FILE="$RUN_DIR/inhibit.pid"

mkdir -p "$RUN_DIR"

is_active() {
    [ -f "$STATE_FILE" ]
}

status() {
    if is_active; then
        echo "1"
    else
        echo "0"
    fi
}

enable_coffee() {
    # 1. Detener el servicio hypridle para cancelar los timeouts de bloqueo y suspensión
    systemctl --user stop hypridle || return 1

    # 2. Iniciar systemd-inhibit para prevenir idle y sleep a nivel logind/systemd
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        : # Ya está corriendo
    else
        systemd-inhibit --what=idle:sleep --who="Modo Cafe" --why="Modo Cafe activo: pantalla encendida" sleep infinity &
        echo $! > "$PID_FILE"
    fi

    # 3. Asegurar que la pantalla esté encendida
    hyprctl dispatch 'hl.dsp.dpms({ action = "enable" })' >/dev/null 2>&1 || true

    # 4. Crear archivo de estado
    touch "$STATE_FILE"

    # 5. Notificar al usuario
    notify-send -a "Modo Café" "Modo Café Activado" "La pantalla no se apagará mientras este modo esté activo." -i "coffee" -t 3000 2>/dev/null || true
}

disable_coffee() {
    # 1. Terminar el inhibidor en segundo plano
    if [ -f "$PID_FILE" ]; then
        kill "$(cat "$PID_FILE")" 2>/dev/null || true
        rm -f "$PID_FILE"
    fi

    # 2. Eliminar archivo de estado
    rm -f "$STATE_FILE"

    # 3. Reactivar el servicio hypridle
    systemctl --user start hypridle 2>/dev/null || true

    # 4. Notificar al usuario
    notify-send -a "Modo Café" "Modo Café Desactivado" "El bloqueo automático de pantalla vuelve a estar activo." -i "coffee" -t 3000 2>/dev/null || true
}

toggle_coffee() {
    if is_active; then
        disable_coffee
    else
        enable_coffee
    fi
}

case "$1" in
    --toggle|toggle)
        toggle_coffee
        ;;
    --status|status)
        status
        ;;
    --enable|enable|--on|on)
        enable_coffee
        ;;
    --disable|disable|--off|off)
        disable_coffee
        ;;
    *)
        toggle_coffee
        ;;
esac
