import gzip
import importlib.util
import json
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch


SOURCE = Path(__file__).resolve().parents[1] / "config/services/database_backup.py"
SPEC = importlib.util.spec_from_file_location("database_backup", SOURCE)
backup = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(backup)


def fake_dump(directory):
    with gzip.open(directory / "mongodb.archive.gz", "wb") as output:
        output.write(b"fixture data")
    (directory / "postgres-globals.sql").write_text("-- fixture\n")
    return {"mongodb_consistency": "live-standalone", "restore_tested": False}


class BackupTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.mount = Path(self.temp.name)
        self.destination = self.mount / "backups"
        for target, kwargs in [
            ("os.geteuid", {"return_value": 0}),
            ("Path.is_mount", {"return_value": True}),
            ("prepare_destination", {"side_effect": lambda path: path.mkdir(mode=0o700, exist_ok=True)}),
            ("dump_databases", {"side_effect": fake_dump}),
        ]:
            parent, _, name = target.rpartition(".")
            owner = getattr(backup, parent) if parent else backup
            mocked = patch.object(owner, name, **kwargs)
            mocked.start()
            self.addCleanup(mocked.stop)

    def create(self):
        return backup.create(self.destination, self.mount, 14)

    def test_publish_verify_and_detect_corruption(self):
        result = self.create()
        self.assertEqual(backup.verify(result)["format"], 1)
        self.assertFalse(list(self.destination.glob(".incomplete-*")))
        (result / "postgres-globals.sql").write_text("changed")
        with self.assertRaisesRegex(ValueError, "Checksum"):
            backup.verify(result)

    def test_missing_mount_creates_nothing(self):
        with patch.object(backup.Path, "is_mount", return_value=False):
            with self.assertRaisesRegex(RuntimeError, "no está montado"):
                self.create()
        self.assertFalse(self.destination.exists())

    def test_failed_dump_keeps_previous_copy(self):
        previous = self.create()
        with patch.object(backup, "dump_databases", side_effect=subprocess.CalledProcessError(1, "mongodump")):
            with self.assertRaises(subprocess.CalledProcessError):
                self.create()
        self.assertTrue(previous.is_dir())
        self.assertFalse(list(self.destination.glob(".incomplete-*")))

    def test_corrupt_gzip_is_not_published_or_pruned(self):
        previous = self.create()
        def corrupt(directory):
            metadata = fake_dump(directory)
            (directory / "mongodb.archive.gz").write_bytes(b"invalid gzip")
            return metadata
        with patch.object(backup, "dump_databases", side_effect=corrupt):
            with self.assertRaises(gzip.BadGzipFile):
                self.create()
        self.assertEqual([p for p in self.destination.iterdir() if p.is_dir()], [previous])

    def test_retention_only_removes_old_managed_backups(self):
        previous = self.create()
        expired = self.destination / "20000101T000000.000000Z"
        previous.rename(expired)
        foreign = self.destination / "19990101T000000.000000Z"
        foreign.mkdir()
        (foreign / "personal.txt").write_text("keep")
        link = self.destination / "19980101T000000.000000Z"
        link.symlink_to(foreign, target_is_directory=True)
        current = self.create()
        self.assertFalse(expired.exists())
        self.assertTrue(current.is_dir())
        self.assertTrue((foreign / "personal.txt").exists())
        self.assertTrue(link.is_symlink())

    def test_manifest_cannot_escape_backup_directory(self):
        current = self.create()
        manifest = current / "manifest.json"
        data = json.loads(manifest.read_text())
        data["files"] = {"../outside": "arbitrary"}
        manifest.write_text(json.dumps(data))
        with self.assertRaisesRegex(ValueError, "Ruta inválida"):
            backup.verify(current)

    def test_destination_cannot_escape_mount(self):
        with self.assertRaises(ValueError):
            backup.create(self.mount.parent / "outside", self.mount, 14)

    def test_dump_all_databases_and_use_oplog_only_for_replica_set(self):
        # Ejercitar el dump real del módulo, sustituyendo solo los ejecutables.
        spec = importlib.util.spec_from_file_location("dump_commands", SOURCE)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        names = ["evert", "name=with'quote\\and spaces"]
        for replica in (False, True):
            with self.subTest(replica=replica):
                destination = self.mount / str(replica)
                destination.mkdir()
                def execute(command, **kwargs):
                    if "psql" in command:
                        return subprocess.CompletedProcess(command, 0, json.dumps(names))
                    if command[0] == "mongosh":
                        hello = {"ok": 1, **({"setName": "rs0"} if replica else {})}
                        return subprocess.CompletedProcess(command, 0, json.dumps(hello))
                    if "stdout" in kwargs:
                        kwargs["stdout"].write(b"dump fixture")
                    return subprocess.CompletedProcess(command, 0)
                with patch.object(module, "run", side_effect=execute) as commands:
                    metadata = module.dump_databases(destination)
                calls = [call.args[0] for call in commands.call_args_list]
                pg_calls = [cmd for cmd in calls if "pg_dump" in cmd]
                self.assertEqual(len(pg_calls), len(names))
                self.assertTrue(all(cmd[:4] == ["runuser", "-u", "postgres", "--"] for cmd in pg_calls))
                self.assertEqual(pg_calls[1][-1], "dbname='name=with\\'quote\\\\and spaces'")
                mongo = next(cmd for cmd in calls if cmd[0] == "mongodump")
                self.assertEqual("--oplog" in mongo, replica)
                self.assertEqual([db["name"] for db in metadata["postgresql"]], names)


if __name__ == "__main__":
    unittest.main()
