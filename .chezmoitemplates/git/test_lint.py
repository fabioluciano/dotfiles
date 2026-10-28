"""Behavioral regression checks for per-file and rendered shell linting."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

LINTER = Path(__file__).resolve().parents[2] / "private_dot_local/bin/executable_dotfiles-lint"


class DotfilesLintTests(unittest.TestCase):
    def test_reports_each_broken_shell_source_and_template(self):
        real_chezmoi = shutil.which("chezmoi")
        if not real_chezmoi:
            self.skipTest("chezmoi is required for the real template renderer")
        if not shutil.which("bash"):
            self.skipTest("bash is required")

        with tempfile.TemporaryDirectory() as temporary:
            base = Path(temporary)
            source = base / "source"
            source.mkdir()
            (source / ".chezmoiscripts").mkdir()
            home = base / "home"
            (home / ".config/chezmoi").mkdir(parents=True)
            config = home / ".config/chezmoi/chezmoi.toml"
            destination = base / "destination"
            config.write_text(f'sourceDir = "{source}"\ndestDir = "{destination}"\n')

            (source / "first.sh").write_text("#!/usr/bin/env bash\necho valid\n")
            (source / "second.sh").write_text("#!/usr/bin/env bash\nif then\n")
            extensionless = source / "broken-script"
            extensionless.write_text("#!/usr/bin/env bash\nif then\n")
            extensionless.chmod(0o755)
            (source / ".chezmoiscripts/broken.sh.tmpl").write_text("#!/usr/bin/env bash\nif then\n")

            subprocess.run(["git", "init", "-q", str(source)], check=True)
            subprocess.run(["git", "-C", str(source), "add", "."], check=True)

            shim_dir = base / "bin"
            shim_dir.mkdir()
            shim = shim_dir / "chezmoi"
            shim.write_text(
                "#!/usr/bin/env python3\n"
                "import subprocess, sys\n"
                f"real = {real_chezmoi!r}\n"
                f"config = {str(config)!r}\n"
                f"source = {str(source)!r}\n"
                "args = sys.argv[1:]\n"
                "if args == ['source-path']:\n"
                "    print(source)\n"
                "    raise SystemExit(0)\n"
                "raise SystemExit(subprocess.run([real, '--config', config, *args]).returncode)\n"
            )
            shim.chmod(0o755)
            environment = dict(os.environ, HOME=str(home), PATH=str(shim_dir) + os.pathsep + os.environ["PATH"])
            result = subprocess.run(
                ["/bin/bash", str(LINTER), "--strict"], cwd=source, env=environment,
                text=True, capture_output=True,
            )

            output = result.stdout + result.stderr
            for expected in (
                "FAIL bash-syntax:second.sh",
                "FAIL bash-syntax:broken-script",
                "FAIL template:.chezmoiscripts/broken.sh.tmpl",
            ):
                with self.subTest(expected=expected):
                    self.assertIn(expected, output)
                    self.assertNotIn("SKIP " + expected[5:], output)

if __name__ == "__main__":
    unittest.main()
