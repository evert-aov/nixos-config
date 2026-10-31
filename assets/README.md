# Fuentes locales de apariencia

`arcmidnight-cursors.tar.gz` conserva el tema instalado de
[ArcMidnight-Cursors](https://github.com/yeyushengfan258/ArcMidnight-Cursors).
Incluye el árbol completo: cursores compilados, SVG originales, scripts de
construcción, README y licencia GPL-3.0. No se modificó el diseño.

El contenido extraído como `source/` tiene el mismo hash NAR que la descarga
anterior fijada en `home.nix`:

```
sha256-VgOpt0rukW0+rSkLFoF9O0xO/qgwieAchAev1vjaqPE=
```

Se conserva esta copia porque la URL anterior apuntaba a `main.zip`, cuyo
contenido puede cambiar. No se pudo obtener un commit verificable del servidor
durante la modificación; no se inventó una revisión. El archivo local ocupa
aproximadamente 1,4 MiB y permite reconstruir sin descargar esa rama.

Para verificarlo, extraer en un directorio temporal y ejecutar
`nix hash path /ruta/temporal/source`. Al actualizar el tema deben conservarse
también sus fuentes y su licencia.
