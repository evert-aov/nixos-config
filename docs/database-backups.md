# Respaldos de bases de datos

Tras activar NixOS, `database-backup.timer` ejecuta una copia diaria a las 04:00,
con un retraso aleatorio de hasta 20 minutos. `Persistent=true` recupera una
ejecución pendiente cuando el equipo vuelve a estar disponible.

Destino: `/mnt/datos/backups/databases`, en el segundo SSD. Retención: 14 días.
Si ese montaje no está disponible, el trabajo falla antes de crear archivos.
El directorio y los archivos se crean restringidos a root. El servicio tiene
prioridad reducida; no detiene PostgreSQL ni MongoDB.

Cada directorio fechado contiene:

- `postgres-globals.sql`: roles y otros objetos globales.
- `postgres-NNNN.dump`: una copia en formato custom por base no plantilla que
  admite conexiones. `manifest.json` relaciona cada archivo con su nombre real.
- `mongodb.archive.gz`: exportación de MongoDB.
- `manifest.json`: fecha UTC, hashes SHA-256 y modalidad de consistencia.

Se usan archivos temporales, publicación por renombrado y sincronización con
el disco. Antes de publicar se comprueban los hashes, se leen completamente los
archivos PostgreSQL con `pg_restore` y se comprueba la descompresión de MongoDB.
Solo después se eliminan los directorios antiguos reconocidos como respaldos.
Una interrupción forzada puede dejar un directorio `.incomplete-*`; nunca se
considera una copia completada ni se elimina automáticamente en una ejecución
posterior.

Estas comprobaciones **no sustituyen una restauración real**. El manifiesto
indica `restore_tested: false` deliberadamente.

## Consistencia

PostgreSQL produce una instantánea consistente por base, sin detener las
lecturas y escrituras normales. Las bases se exportan sucesivamente; no comparten
una única instantánea entre ellas. Ver [pg_dump](https://www.postgresql.org/docs/current/app-pgdump.html).

La configuración actual de MongoDB no declara un replica set. La copia en
caliente de un servidor standalone puede reflejar momentos diferentes entre
colecciones mientras se escribe. El trabajo deja constancia de ello en el
registro y el manifiesto. Si el servidor pertenece a un replica set, añade
`--oplog`; no cambia la configuración de MongoDB. Ver
[mongodump y oplog](https://www.mongodb.com/docs/database-tools/mongodump/#std-option-mongodump.--oplog).

La conexión usa el socket local de PostgreSQL con autenticación peer como
`postgres`, y MongoDB en `127.0.0.1:27017`, conforme a la configuración del
repositorio. Si se cambian sockets, puertos o autenticación, actualizar también
`config/services/database_backup.py`.

## Ejecutar y comprobar

```sh
sudo systemctl start database-backup.service
systemctl status database-backup.service
systemctl list-timers database-backup.timer
sudo journalctl -u database-backup.service -n 80
sudo ls -lt /mnt/datos/backups/databases
sudo database-backup verify /mnt/datos/backups/databases/FECHA
```

`FECHA` se reemplaza por un directorio real. Las horas de nombres/manifiestos
están en UTC; el temporizador utiliza la zona horaria del equipo.

## Ensayo de restauración PostgreSQL

Ejecutar en una terminal normal como `evert`, después de obtener un respaldo.
El ensayo crea un cluster separado, con socket privado y sin escuchar TCP.
Reemplazar `FECHA` y `postgres-NNNN.dump` según el manifiesto.

```bash
trial=$(mktemp -d)
mkdir -m 700 "$trial/socket"
sudo install -m 600 -o "$(id -un)" \
  /mnt/datos/backups/databases/FECHA/postgres-NNNN.dump "$trial/database.dump"
initdb -D "$trial/data" -A trust --no-locale --encoding=UTF8
pg_ctl -D "$trial/data" -l "$trial/server.log" \
  -o "-k $trial/socket -h ''" -w start
createdb -h "$trial/socket" restore_check
pg_restore -h "$trial/socket" -d restore_check --exit-on-error \
  --no-owner --no-privileges --no-tablespaces "$trial/database.dump"
psql -h "$trial/socket" -d restore_check -c '\dt'
# Consultar aquí las tablas y cantidades esperadas por la aplicación.
pg_ctl -D "$trial/data" -m fast -w stop
```

Esto comprueba esquema y datos de una base, sin aplicar roles ni tablespaces de
producción. Repetir para las demás bases. Una prueba completa de recuperación
debe incluir también roles, extensiones y objetos globales en un entorno aparte.
Si hay un error, detener igualmente el cluster temporal con el último comando.
El directorio temporal queda disponible para inspección y eliminación manual.

Para MongoDB, restaurar en **otra instancia de ensayo**, con una versión
compatible y un directorio de datos independiente. Con esa instancia ya
iniciada en un puerto distinto, por ejemplo 37017:

```sh
sudo mongorestore --host 127.0.0.1 --port 37017 --gzip \
  --archive=/mnt/datos/backups/databases/FECHA/mongodb.archive.gz
```

Si el manifiesto indica `oplog`, añadir `--oplogReplay`. Comprobar las colecciones,
índices y consultas de la aplicación en el destino de ensayo. Estos comandos
no se ejecutaron contra las bases reales desde el entorno de herramientas.

La copia en el segundo SSD permite recuperar ante pérdida del disco principal;
no hay una copia externa configurada para pérdida de ambos discos/equipo.
