#!/usr/bin/env python3
"""Respaldos locales en caliente. Nunca modifica ni detiene las bases de origen."""

import argparse
from datetime import datetime, timedelta, timezone
import fcntl
import gzip
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile


STAMP = "%Y%m%dT%H%M%S.%fZ"
BACKUP_NAME = re.compile(r"\d{8}T\d{6}\.\d{6}Z")
MONGO_URI = "mongodb://127.0.0.1:27017/?directConnection=true"


def run(command, **kwargs):
    return subprocess.run(command, check=True, **kwargs)


def postgres(command):
    # Peer authentication; los archivos los abre root antes de cambiar de usuario.
    return ["runuser", "-u", "postgres", "--", *command]


def digest(path):
    with path.open("rb") as source:
        return hashlib.file_digest(source, "sha256").hexdigest()


def check_archive(path):
    if path.suffix == ".dump":
        # Leer todo el archivo, incluyendo los bloques comprimidos de datos.
        run(["pg_restore", "--file=/dev/null", str(path)])
    elif path.suffix == ".gz":
        with gzip.open(path, "rb") as source:
            while source.read(1024 * 1024):
                pass


def verify(directory):
    manifest = json.loads((directory / "manifest.json").read_text())
    if manifest.get("format") != 1 or not manifest.get("files"):
        raise ValueError("Manifiesto de respaldo no reconocido")
    for name, expected in manifest["files"].items():
        if Path(name).name != name or name in (".", ".."):
            raise ValueError("Ruta inválida en el manifiesto")
        archive = directory / name
        if archive.is_symlink() or digest(archive) != expected:
            raise ValueError(f"Checksum incorrecto: {name}")
        check_archive(archive)
    return manifest


def dump_databases(directory):
    psql = ["psql", "-X", "--no-password", "-h", "/run/postgresql", "-d", "postgres"]
    query = "SELECT coalesce(json_agg(datname ORDER BY datname), '[]'::json) FROM pg_database WHERE datallowconn AND NOT datistemplate"
    names = json.loads(run(postgres([*psql, "-At", "-c", query]), capture_output=True, text=True).stdout)
    if not names:
        raise ValueError("PostgreSQL no devolvió ninguna base de datos")
    with (directory / "postgres-globals.sql").open("wb") as output:
        run(postgres(["pg_dumpall", "--no-password", "-h", "/run/postgresql", "--globals-only"]), stdout=output)
    databases = []
    for index, name in enumerate(names):
        filename = f"postgres-{index:04d}.dump"
        # libpq interpreta nombres con '=' como conninfo: escaparlos explícitamente.
        escaped = name.replace("\\", "\\\\").replace("'", "\\'")
        with (directory / filename).open("wb") as output:
            run(postgres(["pg_dump", "--no-password", "-h", "/run/postgresql",
                          "--format=custom", "--dbname", f"dbname='{escaped}'"]), stdout=output)
        databases.append({"name": name, "file": filename})

    hello = json.loads(run(["mongosh", MONGO_URI, "--quiet", "--eval", "JSON.stringify(db.hello())"],
                           capture_output=True, text=True).stdout)
    if not hello.get("ok"):
        raise ValueError("MongoDB no confirmó su estado")
    replica = bool(hello.get("setName"))
    command = ["mongodump", "--uri", MONGO_URI, "--gzip",
               f"--archive={directory / 'mongodb.archive.gz'}"]
    if replica:
        command.append("--oplog")
    else:
        print("MongoDB standalone: copia en caliente sin consistencia global entre colecciones durante escrituras.", flush=True)
    run(command)
    return {
        "postgresql": databases,
        "mongodb_consistency": "oplog" if replica else "live-standalone",
        "restore_tested": False,
    }


def prune(destination, retention_days, now, current):
    cutoff = now - timedelta(days=retention_days)
    for candidate in destination.iterdir():
        if candidate == current or candidate.is_symlink() or not candidate.is_dir():
            continue
        if not BACKUP_NAME.fullmatch(candidate.name):
            continue
        try:
            created = datetime.strptime(candidate.name, STAMP).replace(tzinfo=timezone.utc)
            manifest = json.loads((candidate / "manifest.json").read_text())
        except (OSError, ValueError):
            continue
        if created < cutoff and manifest.get("format") == 1 and manifest.get("files"):
            shutil.rmtree(candidate)


def prepare_destination(destination):
    destination.mkdir(mode=0o700, parents=True, exist_ok=True)
    if destination.stat().st_uid != 0:
        raise PermissionError("El directorio de respaldos debe pertenecer a root")
    destination.chmod(0o700)


def create(destination, mount, retention_days):
    if os.geteuid() != 0:
        raise PermissionError("Ejecuta create como root (sudo database-backup create ...)")
    if retention_days < 1:
        raise ValueError("La retención debe ser al menos de un día")
    if not mount.is_mount():
        raise RuntimeError(f"{mount} no está montado; se evita escribir en el disco raíz")
    if destination.is_symlink() or not destination.resolve().is_relative_to(mount.resolve()):
        raise ValueError("El destino debe estar dentro del montaje indicado, sin enlace simbólico final")
    prepare_destination(destination)
    with (destination / ".lock").open("a") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        now = datetime.now(timezone.utc)
        final = destination / now.strftime(STAMP)
        staging = Path(tempfile.mkdtemp(prefix=".incomplete-", dir=destination))
        try:
            metadata = dump_databases(staging)
            metadata.update(format=1, created_at=now.isoformat(), files={
                path.name: digest(path) for path in sorted(staging.iterdir()) if path.is_file()
            })
            (staging / "manifest.json").write_text(json.dumps(metadata, indent=2, ensure_ascii=False) + "\n")
            verify(staging)
            # Forzar datos y directorios antes de publicar una copia como terminada.
            for path in staging.iterdir():
                with path.open("rb") as archive:
                    os.fsync(archive.fileno())
            sync_directory(staging)
            staging.rename(final)
            sync_directory(destination)
            # Nunca podar copias anteriores si falla el respaldo o su comprobación.
            prune(destination, retention_days, now, final)
            print(f"Respaldo verificado: {final}", flush=True)
            return final
        finally:
            if staging.exists():
                shutil.rmtree(staging)


def sync_directory(path):
    descriptor = os.open(path, os.O_RDONLY | os.O_DIRECTORY)
    try:
        os.fsync(descriptor)
    finally:
        os.close(descriptor)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    create_parser = commands.add_parser("create")
    create_parser.add_argument("--destination", type=Path, default=Path("/mnt/datos/backups/databases"))
    create_parser.add_argument("--mount", type=Path, default=Path("/mnt/datos"))
    create_parser.add_argument("--retention-days", type=int, default=14)
    verify_parser = commands.add_parser("verify")
    verify_parser.add_argument("directory", type=Path)
    args = parser.parse_args()
    os.umask(0o077)
    if args.command == "create":
        create(args.destination, args.mount, args.retention_days)
    else:
        metadata = verify(args.directory)
        print(f"Integridad correcta. MongoDB: {metadata['mongodb_consistency']}. Restauración real: pendiente si no se ha ensayado por separado.")


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, RuntimeError, subprocess.CalledProcessError) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        sys.exit(1)
