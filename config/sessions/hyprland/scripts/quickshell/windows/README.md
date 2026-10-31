# Selector de ventanas

Panel integrado en `Main.qml`, con los mismos colores de Matugen y el mismo
gestor de widgets que el selector de fondos. Incluye ventanas de todos los
escritorios y monitores, ordenadas por el historial de foco de Hyprland.
Usa un carrusel transparente de ancho completo: la ventana seleccionada se
amplía en el centro y las demás aparecen como tarjetas inclinadas a los lados.
Las vistas previas conservan su orientación dentro de los marcos inclinados.

- **Super+Tab:** abrir y seleccionar la siguiente ventana; repetir para avanzar.
- **Super+Shift+Tab:** abrir/recorrer en sentido inverso.
- **Tab / Shift+Tab / flechas:** recorrer las tarjetas con el panel abierto.
- **Rueda del ratón o botones ‹ / ›:** recorrer el carrusel.
- **Enter o clic:** enfocar la ventana y cambiar a su escritorio.
- **Esc, × o clic fuera:** cerrar sin cambiar de ventana.

El panel permanece abierto al soltar Super, como el selector de fondos.
También aparece en los módulos de la guía (`Super+H`) y se puede abrir con:

```sh
bash ~/.config/hypr/scripts/qs_manager.sh toggle windows
```

Las miniaturas usan `ScreencopyView` de Quickshell 0.3 y el protocolo de captura
de ventanas de Hyprland. Solo capturan las tarjetas visibles; si el compositor
no entrega imagen, se muestra el icono y la ventana sigue siendo seleccionable.
No se guardan capturas en disco ni se instalan plugins de Hyprland.

## Aplicar desde este repositorio

Home Manager publica `scripts` en el Nix store y copia `config/keybindings.lua`.
Editar el repositorio por sí solo no cambia la configuración instalada. Para
incluir también archivos nuevos sin tener que crear un commit:

```sh
cd /home/evert/nixos-configuration
sudo nixos-rebuild switch --impure --flake path:/home/evert/nixos-configuration#nixos
hyprctl reload
bash ~/.config/hypr/scripts/reload.sh
```

Si se usa `./deploy.sh`, primero hay que seguir sus comprobaciones de Git:
requiere archivos registrados y cambios confirmados.

## Comprobación manual en Hyprland

Abrir varias aplicaciones en dos escritorios; recorrer con Super+Tab y
Shift+Tab, confirmar con Enter y comprobar el cambio de escritorio. Repetir
con clic y con una ventana a pantalla completa. Cerrar una ventana mientras el
panel está abierto y comprobar que desaparece sin perder la navegación.
Verificar Esc, clic exterior y una cantidad de ventanas que requiera scroll.

API de captura: https://quickshell.org/docs/v0.3.0/types/Quickshell.Wayland/ScreencopyView/
