# Guía de despliegue

## Flujo de trabajo completo

### 1. Editar

Los archivos se editan **siempre en el repo** `/home/evert/nixos-configuration/`:

| Qué quieres cambiar | Dónde se edita |
| --- | --- |
| keybinds, autostart, reglas, monitores, env | `config/sessions/hyprland/config/*.conf` |
| quickshell (QML, watchers, scripts) | `config/sessions/hyprland/scripts/quickshell/` |
| scripts de hypr (qs_manager, caching, etc.) | `config/sessions/hyprland/scripts/` |
| paquetes del sistema (vivaldi, bottles, neovim...) | `configuration.nix`, `home.nix` |

### 2. Commitear (regla de oro)

**Commitéa TODO antes de desplegar.** Nix, cuando el flake está en un repo git,
EXCLUYE los archivos sin trackear del build. Si dejas un archivo nuevo como
`??` (untracked), el `nixos-rebuild switch` lo despliega a medias y rompe cosas
en silencio (esto pasó con `sysmon/SystemMonitorPopup.qml`: el popup se
registraba en la UI pero el archivo nunca llegaba al sistema).

- Cualquier archivo nuevo de quickshell/hypr → `git add` + `git commit`.
- Si un archivo no debe ir al repo, añádelo a `.gitignore`.

`deploy.sh` rechaza el despliegue si hay archivos untracked o cambios sin
commitear, así que no se puede repetir ese error.

### 3. Sincronizar

- **`~/.config/hypr/scripts/`** → es un symlink al nix store (inmutable, solo
  lectura). Nunca lo edites a mano; cualquier cambio ahí requiere desplegar.
- **`~/.config/hypr/config/`** → se sincroniza SOLA: `copyHyprConfig` hace un
  `rsync` de `config/sessions/hyprland/config/` a esa carpeta durante cada
  `nixos-rebuild switch`. No hay que copiar nada a mano si despliegas.
- **Vía rápida para cambios SOLO de hypr.conf** (keybinds, reglas, autostart)
  sin esperar el rebuild:

  ```bash
  cd ~/nixos-configuration
  rsync -a --update config/sessions/hyprland/config/ ~/.config/hypr/config/
  hyprctl reload
  ```

  (es el mismo rsync que hace `copyHyprConfig`, aplicado al momento).

### 4. Desplegar

```bash
cd ~/nixos-configuration
./deploy.sh
```

El script hace y verifica:

1. Árbol de git limpio y completo (sin untracked ni dirty).
2. Construye `home-manager-files` y comprueba que el build contenga
   `quickshell/sysmon/` y `watchers/sys_wait.sh`, sin rutas stale
   `config/quickshell`.
3. `sudo nixos-rebuild switch --flake .#nixos` (en este paso `copyHyprConfig`
   sincroniza `config/` automáticamente).
4. Verifica el despliegue en vivo (la copia real en `~/.config/hypr/scripts/`).
5. Reinicia quickshell y comprueba que arrancó.

### 5. Probar después del despliegue

- `SUPER+A` → applauncher
- `SUPER+SHIFT+B` → batería
- `SUPER+M` → monitores
- Click en el área de stats de la TopBar → popup de sysmon

## ¿Sigue siendo necesario el comando directo?

No. El antiguo

```bash
cd ~/nixos-configuration && NIXPKGS_ALLOW_UNFREE=1 sudo nixos-rebuild switch --flake .#nixos
```

sigue funcionando (es exactamente lo que corre `deploy.sh` en el paso 3), pero
NO verifica el contenido del build ni reinicia quickshell. Usa siempre
`./deploy.sh`.

## Cómo está organizado quickshell

- **Una sola copia**: `~/.config/hypr/scripts/quickshell/` (symlink a nix store,
  desplegada desde `config/sessions/hyprland/scripts/quickshell/`). No existe
  copia manual en `~/.config/hypr/config/` — no la crees de nuevo.
- Los scripts del quickshell arrancan desde esa ruta (`autostart.conf`,
  `qs_manager.sh`, `reload.sh` todos apuntan ahí). Si quickshell no responde a
  un atajo, primero comprueba `pgrep -af quickshell` y que corra desde
  `~/.config/hypr/scripts/quickshell/Shell.qml`.

## Clima (OpenWeather)

La clave vive en `~/.cache/quickshell/calendar/.env` (la copia desplegada en el
nix store es de solo lectura, no puede guardar el `.env`). `weather.sh` la lee
de ahí automáticamente.
