#!/usr/bin/env bash
set -euo pipefail

FLAKE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$FLAKE_DIR"
MODE="${1:---switch}"
case "$MODE" in
    --check|--build|--switch) ;;
    *) echo "Uso: $0 [--check|--build|--switch]" >&2; exit 2 ;;
esac
if (( $# > 1 )); then
    echo "Solo se admite un modo de ejecución." >&2
    exit 2
fi

# path: incluye los archivos nuevos sin exigir un commit de los cambios locales.
FLAKE="path:$FLAKE_DIR"
CONFIG="nixosConfigurations.nixos.config"
REQUIRED=(
    Shell.qml Main.qml BarData.qml SysData.qml ShellSettings.qml Theme.qml WatchedJson.qml
    windows/WindowSwitcher.qml sysmon/SystemMonitorPopup.qml watchers/system_metrics.py
)
check_shell_files() {
    local directory="$1" file
    for file in "${REQUIRED[@]}"; do
        if [[ ! -f "$directory/$file" ]]; then
            echo "ERROR: falta $directory/$file" >&2
            return 1
        fi
    done
    if rg -n 'config/quickshell' "$directory"; then
        echo "ERROR: se encontraron rutas antiguas de Quickshell." >&2
        return 1
    fi
}

echo "Comprobando sintaxis y pruebas locales..."
while IFS= read -r -d '' source_file; do
    nix-instantiate --parse "$source_file" >/dev/null
done < <(rg --files -0 -g '*.nix')
for source_file in deploy.sh config/sessions/hyprland/scripts/{lock,coffee,qs_manager,caching}.sh; do
    bash -n "$source_file"
done
zsh -n config/programs/zsh/zsh-init.sh
python3 -B -m unittest discover -s tests -v
check_shell_files "$FLAKE_DIR/config/sessions/hyprland/scripts/quickshell"
if [[ "$MODE" == --check ]]; then
    echo "Comprobaciones locales correctas. Todavía no se ha construido ni activado NixOS."
    exit 0
fi

# El instalador privativo queda fuera de Git, con contenido fijado en home.nix.
VENDOR_NAME="CiscoPacketTracer_901_Ubuntu_64bit.deb"
VENDOR_HASH="sha256-biYiu0gukHHLRvwXiOSK3jblrslvwqwXMCHG7og6JpY="
VENDOR_STORE=$(nix-store --print-fixed-path --recursive sha256 "$VENDOR_HASH" "$VENDOR_NAME")
if [[ ! -f "$VENDOR_STORE" ]]; then
    VENDOR_SOURCE="$HOME/.local/share/nixos-sources/$VENDOR_NAME"
    if [[ ! -f "$VENDOR_SOURCE" ]]; then
        echo "Falta $VENDOR_SOURCE. Copia allí el instalador original de Cisco 9.0.1." >&2
        exit 1
    fi
    if [[ "$(nix hash path --type sha256 "$VENDOR_SOURCE")" != "$VENDOR_HASH" ]]; then
        echo "El instalador de Packet Tracer no coincide con el hash fijado." >&2
        exit 1
    fi
    nix-store --add-fixed --recursive sha256 "$VENDOR_SOURCE"
fi

# Tomar una sola instantánea: build y switch usarán exactamente las mismas fuentes.
SNAPSHOT=$(nix flake metadata --json --no-write-lock-file "$FLAKE" | jq -er '.path')
SNAPSHOT_FLAKE="path:$SNAPSHOT"
echo "Construyendo NixOS y los archivos de Home Manager..."
SYSTEM=$(nix build --impure --no-write-lock-file --no-link --print-out-paths \
    "$SNAPSHOT_FLAKE#$CONFIG.system.build.toplevel")
HMF=$(nix build --impure --no-write-lock-file --no-link --print-out-paths \
    "$SNAPSHOT_FLAKE#$CONFIG.home-manager.users.evert.home-files")
check_shell_files "$HMF/.config/hypr/scripts/quickshell"
[[ -x "$SYSTEM/sw/bin/database-backup" ]]
[[ -f "$SYSTEM/etc/systemd/system/database-backup.timer" ]]
if [[ "$MODE" == --build ]]; then
    echo "Construcción verificada: $SYSTEM"
    echo "No se activó el sistema."
    exit 0
fi

echo "Activando la configuración construida..."
sudo nixos-rebuild switch --impure --no-write-lock-file --flake "$SNAPSHOT_FLAKE#nixos"
check_shell_files "$HOME/.config/hypr/scripts/quickshell"
systemctl is-active postgresql.service mongodb.service database-backup.timer
if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    hyprctl reload
    # La ruta pública sigue siendo estable aunque Home Manager cambie su destino.
    bash "$HOME/.config/hypr/scripts/reload.sh"
fi
echo "Despliegue terminado. El respaldo se ejecutará mediante su temporizador diario."
echo "Para realizar el primero ahora: sudo systemctl start database-backup.service"
