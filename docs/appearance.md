# Transparencia de Quickshell

## Modo claro y oscuro automático

Al seleccionar un fondo, `wallpaper/apply_palette.sh` mide su luminosidad
media sobre una muestra de 64 × 64 píxeles. Desde 0,55 elige `light`; por debajo,
`dark`. Las imágenes de poco color conservan el esquema neutro. Matugen genera
las plantillas con ese modo, incluido Quickshell, terminales, GTK y la paleta
persistente de GDM. Para vídeos se analiza la miniatura del selector.

La preferencia se guarda en `~/.cache/quickshell/theme-mode` y se aplica a GTK
por GSettings, también al iniciar Hyprland. GDM elige su hoja de estilo clara
u oscura según la paleta guardada al arrancar. Después de instalar estos cambios,
seleccionar de nuevo el fondo genera la primera paleta automática. Las apps que
no recargan sus estilos en vivo pueden necesitar volver a abrirse.

Se comprobó en modo de simulación que `cqplbyj4nczf1.jpeg` elige `light` y una
imagen oscura elige `dark`, sin modificar el tema de la sesión durante la prueba.

Los fondos comparten valores en
`config/sessions/hyprland/scripts/quickshell/Theme.qml`:

| Superficie | Opacidad | Fondo visible |
| --- | --- | --- |
| Paneles y barra lateral | 72 % | 28 % |
| Notificaciones y menús elevados | 82 % | 18 % |
| Barra superior | 62 % | 38 % |
| Controles del selector de ventanas y fondos | 76 % | 24 % |

La transparencia se aplica al color de los fondos. La paleta de texto,
iconos y estados conserva su opacidad; las animaciones de entrada y salida
siguen funcionando. Las tarjetas interiores y decoraciones pueden aumentar
la opacidad efectiva donde se superponen.

Los valores reaccionan a la paleta del fondo de pantalla igual que antes.
Para ajustar la intensidad, cambiar `panelOpacity`, `raisedOpacity`,
`barOpacity` y `toolbarOpacity`: un número menor deja ver más el escritorio.

Aplicar mediante `./deploy.sh` desde la sesión gráfica. El despliegue instala
los QML y recarga Quickshell; una recarga por sí sola no instala los cambios
si `~/.config/hypr/scripts` sigue apuntando a la generación anterior de Nix.

## Pantalla de inicio de sesión (GDM)

La configuración está en `config/login/gdm.nix` y los estilos en
`config/login/gdm.css`. Al arrancar, GDM toma una copia del último fondo que
seleccionaste en Quickshell (`~/.cache/quickshell/wallpaper_picker/current_wallpaper.png`).
Matugen guarda además su paleta en `~/.cache/matugen-gdm-colors.json` para el
greeter; el servicio la valida y deriva los colores de los fondos, textos y acentos.
Así también se conserva una captura de los fondos animados; una imagen local
sirve de respaldo si aún no existe una selección. Un servicio copia la imagen
antes de que GDM inicie, por lo que el fondo se actualiza en cada arranque.
Incluye una capa oscura para el contraste, tarjetas translúcidas y acentos
violetas. El saludo es **“Welcome, Evert”** y el logotipo está en
`config/login/evert-logo.svg`. El reloj usa 24 horas e incluye el día de la semana.

Las opciones `picture-uri` y `picture-uri-dark` que antes se escribían bajo
`org/gnome/login-screen` no existen en el esquema de GDM instalado y se retiraron.
El fondo se aplica ahora mediante el estilo `#lockDialogGroup` de GNOME Shell.

El módulo extrae las hojas de estilo originales de la versión instalada y
añade las reglas personales. Un [overlay de recursos de GLib](https://docs.gtk.org/gio/struct.Resource.html)
las carga únicamente en `org.gnome.Shell@gdm.service`. La unidad original,
la autenticación y la selección de sesión siguen a cargo de GDM. No se
recompila GNOME Shell ni se escriben archivos dentro de su paquete. El estilo
de alto contraste conserva los recursos originales.

Aplicar con `./deploy.sh` y reiniciar cuando quieras ver el fondo actual. El
despliegue no fuerza un reinicio de GDM. Reiniciar manualmente
`display-manager` cerraría la sesión gráfica actual.

Se comprobaron la sintaxis Nix y las hojas clara/oscura con el parser St de
GNOME Shell 50.4 instalado. También se verificó que GLib carga el overlay y
conserva el estilo original de alto contraste. La construcción completa de
NixOS y la comprobación visual en GDM requieren la sesión del equipo: el
entorno de herramientas no permite conectar al daemon de Nix ni iniciar
una pantalla de acceso real.

Para volver al aspecto original conservando GDM, retirar el bloque
`systemd.user.services."org.gnome.Shell@gdm"` del módulo y aplicar de nuevo.
El saludo, reloj y logotipo se personalizan por separado en ese mismo archivo.
