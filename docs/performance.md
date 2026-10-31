# Optimización del shell y servicios

Cambios en la configuración:

- Retirados Ollama, Open WebUI y la integración de Stewart (widget, entrada de
  la guía y función `stsetup`). No se borraron modelos, bases de datos ni
  proyectos personales almacenados fuera del repositorio.
- MongoDB y PostgreSQL conservan `enable = true`.
- Docker, libvirt y VirtualBox conservan su configuración de arranque: no se
  presupone que los contenedores o máquinas sean prescindibles.
- EasyEffects sigue gestionado por Home Manager; se eliminó su activación
  redundante desde Hyprland y una llamada a `settings_watcher.sh`, que no
  existe en este repositorio.
- Se conservó zram y se restablecieron `swappiness = 60` y
  `vfs_cache_pressure = 100`, los valores estándar, también al aplicar `switch`.
  Se evita así que los ajustes anteriores persistan hasta el siguiente reinicio.

## Quickshell

`BarData.qml` concentra los lectores de audio, red, Bluetooth, batería,
teclado, música, clima y escritorios. Las barras de todos los monitores usan
esa misma instancia. El IPC `topbar` también tiene una sola instancia.

`SysData.qml` mantiene un único proceso `watchers/system_metrics.py`:

- CPU global y memoria cada 3 segundos.
- Con un panel de estadísticas visible: cada 2 segundos, incluyendo núcleos,
  temperatura y velocidades de red.
- Tasas calculadas con el tiempo real entre muestras; sin comandos externos
  ni una espera bloqueante de medio segundo por consulta.
- El recolector termina cuando Quickshell cierra su entrada estándar.

`Theme.qml` y `ShellSettings.qml` comparten lecturas mediante `WatchedJson.qml`.
Los archivos se vigilan con `FileView`; no hay un `cat` periódico por widget
ni un `inotifywait` por cada instancia de `Scaler`. Una escritura parcial
conserva el último JSON válido. Un archivo ausente se vuelve a intentar cada
2 segundos hasta que esté disponible.

Los scripts de caché crean solo los directorios solicitados. Ya no recorren
todos los widgets cada vez que se inicia un listener. El selector de ventanas
usa IPC directo si el shell está disponible, evitando esa preparación en cada
pulsación de Super+Tab. Los reintentos de carátulas de música están limitados.

## Energía, mantenimiento y terminales

- CPU: `schedutil`, que figura entre los governors disponibles del equipo.
  El driver observado es `acpi-cpufreq`. No hay interfaz `amd_pstate` ni
  `acpi_cppc` expuesta; se conserva el parámetro existente `amd_pstate=active`,
  pero no se presupone que esté funcionando. Se mantiene power-profiles-daemon.
- `hypridle` queda a cargo de Home Manager. Bloqueo a los 5 minutos, pantalla
  apagada a los 10 y suspensión a los 15. El bloqueo Quickshell evita instancias
  duplicadas y se configura `inhibit_sleep=3` para esperar la notificación de
  bloqueo antes de dormir. Los comandos DPMS usan la sintaxis Lua actual.
  Referencia: [hypridle](https://wiki.hypr.land/hypr-ecosystem/user/hypridle/).
- El modo café controla el servicio, sin un `killall -9` adicional, y usa el
  comando DPMS actualizado. Conserva su comportamiento de inhibir suspensión
  y desactivar los timeouts mientras está activo.
- TRIM semanal explícito, aunque ya era el valor predeterminado de NixOS.
  Optimización del almacén Nix los domingos a las 05:30, con la prioridad baja
  y comprobación de alimentación de CA del módulo de NixOS. La recolección de
  generaciones conserva sus 14 días anteriores.
- Fastfetch se muestra automáticamente solo en la primera terminal interactiva
  de cada sesión Hyprland. El comando `fetch` sigue disponible manualmente.
  Cada ejecución usa su propio archivo temporal y lo elimina al terminar.
- [Respaldos diarios de las bases de datos](database-backups.md), sin detenerlas.

## Fuentes reproducibles

Packet Tracer usa `requireFile` con hash NAR fijo, reutilizando el instalador
que ya existe en el almacén Nix. Hay una copia adicional verificada en
`~/.local/share/nixos-sources/CiscoPacketTracer_901_Ubuntu_64bit.deb`.
`deploy.sh` la registra automáticamente si falta en el almacén. No se añade
el instalador privativo a Git y no se borra el original de Downloads.

El tema ArcMidnight usa una [copia local con fuentes y licencia](../assets/README.md),
idéntica al contenido instalado; ya no depende de descargar una rama mutable.

## Validación y aplicación

Pruebas del recolector:

```sh
python3 -B -m unittest discover -s tests -v
```

También se verificaron, en Quickshell sin pantalla, las lecturas compartidas,
la propagación de ajustes, los reemplazos atómicos de JSON, el ciclo de
suscripción de un panel visible/oculto y dos barras con fuentes simuladas.
Estas pruebas no sustituyen la comprobación con los dispositivos reales.

El despliegue incluye los archivos nuevos sin exigir un commit, toma una sola
instantánea de las fuentes, construye NixOS y los archivos de Home Manager,
verifica los componentes nuevos y después activa esa misma instantánea. Los
errores de construcción se muestran y detienen el proceso. No se matan
indiscriminadamente las instancias de Quickshell.

```sh
cd /home/evert/nixos-configuration
./deploy.sh --check   # Sintaxis y pruebas, sin construcción ni activación
./deploy.sh --build   # Construir y verificar, sin activar
./deploy.sh           # Comprobar, construir y activar
```

Cerrar y volver a iniciar la sesión gráfica una vez tras la primera activación
garantiza que no quede el `hypridle` antiguo arrancado por Hyprland. En la nueva
sesión deben verse un solo proceso `hypridle` y su servicio de usuario activo.
El comando de despliegue vuelve a cargar Hyprland y Quickshell si se ejecuta
desde la sesión gráfica.

Comprobar después que MongoDB y PostgreSQL siguen activos, que las barras
muestran audio/red/batería y que cambiar el fondo actualiza los colores.
Con varios monitores debe existir un solo proceso `system_metrics.py` por
instancia de Quickshell.

El entorno de herramientas no permite conectar al daemon de Nix ni al
systemd del equipo. Se validó la sintaxis Nix, pero la construcción completa
y la activación quedan pendientes de ejecutar en la sesión del usuario.
Pasan 14 pruebas automatizadas: recolector, respaldo fallido/corrupto,
retención, montaje ausente y bloqueo del despliegue ante build fallido o
artefactos incompletos. Los respaldos se prueban con fixtures; el intento de
ensayo PostgreSQL real en un cluster temporal fue bloqueado al abrir su socket.
