#!/usr/bin/env bash
set -euo pipefail

FLAKE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$FLAKE_DIR"

echo "=== [1/5] Verificando que el árbol de git esté completo ==="
UNTRACKED=$(git ls-files --others --exclude-standard)
if [[ -n "$UNTRACKED" ]]; then
    echo "ERROR: hay archivos sin trackear. Nix los EXCLUYE del build"
    echo "(esto causó el bug de sysmon que se desplegó a medias)."
    echo "$UNTRACKED"
    echo "=> git add <archivos> && git commit, o añádelos a .gitignore"
    exit 1
fi
if [[ -n "$(git diff --name-only)" ]]; then
    echo "ERROR: hay cambios sin commitear:"
    git diff --name-only
    echo "=> git add && git commit antes de desplegar"
    exit 1
fi
echo "OK: árbol limpio y completo"

echo "=== [2/5] Construyendo y verificando home-manager-files ==="
HMF=$(NIXPKGS_ALLOW_UNFREE=1 nix build --no-link --print-out-paths \
    .#nixosConfigurations.nixos.config.home-manager.users.evert.home-files 2>/dev/null)
SCRIPTS=$(readlink "$HMF/.config/hypr/scripts")
echo "scripts -> $SCRIPTS"
for f in quickshell/sysmon/SystemMonitorPopup.qml quickshell/watchers/sys_wait.sh; do
    if [[ ! -e "$SCRIPTS/$f" ]]; then
        echo "ERROR: el build no contiene $f"
        exit 1
    fi
done
if grep -rq "config/quickshell" "$SCRIPTS/quickshell"; then
    echo "ERROR: el build contiene rutas stale 'config/quickshell':"
    grep -rl "config/quickshell" "$SCRIPTS/quickshell"
    exit 1
fi
echo "OK: build contiene sysmon y sin rutas stale"

echo "=== [3/5] Desplegando (sudo nixos-rebuild switch) ==="
NIXPKGS_ALLOW_UNFREE=1 sudo nixos-rebuild switch --flake .#nixos

echo "=== [4/5] Verificando el despliegue en vivo ==="
LIVE="$HOME/.config/hypr/scripts/quickshell"
for f in sysmon/SystemMonitorPopup.qml watchers/sys_wait.sh; do
    if [[ ! -e "$LIVE/$f" ]]; then
        echo "ERROR: el despliegue en vivo no contiene $f"
        exit 1
    fi
done
if grep -rq "config/quickshell" "$LIVE"; then
    echo "ERROR: el despliegue en vivo tiene rutas stale 'config/quickshell'"
    exit 1
fi
echo "OK: despliegue en vivo correcto"

echo "=== [5/5] Reiniciando quickshell ==="
pkill -f "quickshell.*Shell.qml" || true
sleep 1
"$HOME/.config/hypr/scripts/qs_manager.sh" toggle applauncher || true
sleep 2
if pgrep -f "quickshell.*Shell.qml" >/dev/null; then
    echo ""
    echo "DESPLIEGUE OK"
    echo "Prueba: SUPER+A, SUPER+SHIFT+B, SUPER+M y el popup de sysmon (click en el área de stats de la TopBar)"
else
    echo "ERROR: quickshell no arrancó tras reiniciar"
    exit 1
fi
