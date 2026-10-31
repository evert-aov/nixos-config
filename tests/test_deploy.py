import os
from pathlib import Path
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]


class DeployTests(unittest.TestCase):
    def test_activation_requires_successful_build_and_complete_artifacts(self):
        with tempfile.TemporaryDirectory() as directory:
            fixture = Path(directory)
            binaries = fixture / "bin"
            binaries.mkdir()
            system = fixture / "system"
            (system / "sw/bin").mkdir(parents=True)
            command = system / "sw/bin/database-backup"
            command.touch()
            command.chmod(0o700)
            (system / "etc/systemd/system").mkdir(parents=True)
            (system / "etc/systemd/system/database-backup.timer").touch()
            home_files = fixture / "home-files"
            (home_files / ".config/hypr").mkdir(parents=True)
            (home_files / ".config/hypr/scripts").symlink_to(ROOT / "config/sessions/hyprland/scripts")
            vendor = fixture / "vendor.deb"
            vendor.touch()
            mocks = {
                "nix-instantiate": "exit 0",
                # El despliegue invoca la suite; evitar recursión durante esta prueba.
                "python3": "exit 0",
                "nix-store": 'printf "%s\\n" "$FIXTURE/vendor.deb"',
                "nix": '''
                    printf '%s\n' "$*" >> "$FIXTURE/nix.log"
                    if [[ "$1" == flake ]]; then
                        printf '{"path":"%s/snapshot"}\n' "$FIXTURE"
                    elif [[ "$1" == build ]]; then
                        [[ "${FAIL_BUILD:-0}" == 1 ]] && exit 1
                        if [[ "${@: -1}" == *.system.build.toplevel ]]; then
                            printf '%s/system\n' "$FIXTURE"
                        else
                            printf '%s/home-files\n' "$FIXTURE"
                        fi
                    else
                        exit 2
                    fi
                ''',
                "sudo": 'printf "%s\\n" "$*" >> "$FIXTURE/activation.log"',
                "systemctl": "exit 0",
            }
            for name, body in mocks.items():
                path = binaries / name
                path.write_text("#!/usr/bin/env bash\nset -eu\n" + body + "\n")
                path.chmod(0o700)
            env = {**os.environ, "PATH": f"{binaries}:{os.environ['PATH']}",
                   "FIXTURE": str(fixture), "HOME": str(home_files)}
            env.pop("HYPRLAND_INSTANCE_SIGNATURE", None)
            log = fixture / "activation.log"
            for scenario in ("build-failure", "missing-artifact"):
                with self.subTest(scenario=scenario):
                    if scenario == "missing-artifact":
                        command.unlink()
                    result = subprocess.run(["bash", str(ROOT / "deploy.sh"), "--switch"],
                                            env={**env, "FAIL_BUILD": "1" if scenario == "build-failure" else "0"},
                                            capture_output=True, text=True)
                    self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
                    self.assertFalse(log.exists())
            command.touch()
            command.chmod(0o700)
            result = subprocess.run(["bash", str(ROOT / "deploy.sh"), "--build"], env=env,
                                    capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertFalse(log.exists())
            result = subprocess.run(["bash", str(ROOT / "deploy.sh"), "--switch"], env=env,
                                    capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertIn(f"--flake path:{fixture}/snapshot#nixos", log.read_text())


if __name__ == "__main__":
    unittest.main()
