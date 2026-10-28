"""Scratch-stub smoke tests for bootstrap hook failure and idempotence behavior."""

import os
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


class HookSmokeTests(unittest.TestCase):
    def render_hook(self, source):
        return subprocess.run(
            ["chezmoi", "execute-template", "--file", str(source)],
            cwd=ROOT,
            text=True,
            capture_output=True,
            check=True,
        ).stdout

    def run_hook(self, source, home, bin_dir):
        env = os.environ | {"HOME": str(home), "PATH": f"{bin_dir}:{os.environ['PATH']}"}
        return subprocess.run(["bash", str(source)], env=env, text=True, capture_output=True)

    def test_plugin_failures_retry_and_known_states_are_idempotent(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            home, bindir = root / "home", root / "bin"
            home.mkdir(); bindir.mkdir()
            (home / ".OmpMarketplaces").write_text("broken-market\nalready-market\n")
            (home / ".OmpPlugins").write_text("broken-plugin\nalready-plugin\n")
            omp = bindir / "omp"
            omp.write_text("""#!/bin/bash
case "$*" in
  *broken-market) echo 'network failure'; exit 7;;
  *already-market) echo 'already exists'; exit 1;;
  *broken-plugin) echo 'install failure'; exit 8;;
  *already-plugin) echo 'already installed'; exit 1;;
esac
""")
            omp.chmod(0o755)
            hook = root / "omp.sh"
            hook.write_text(self.render_hook(ROOT / ".chezmoiscripts/run_onchange_after_53-omp-plugins.sh.tmpl"))
            result = self.run_hook(hook, home, bindir)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("network failure", result.stderr)
            self.assertIn("install failure", result.stderr)
            self.assertIn("already exists", result.stdout)
            self.assertIn("already installed", result.stdout)
            (home / ".OmpMarketplaces").write_text("already-market\n")
            (home / ".OmpPlugins").write_text("already-plugin\n")
            result = self.run_hook(hook, home, bindir)
            self.assertEqual(result.returncode, 0)

    def test_dock_keeps_existing_items_when_required_bundle_is_missing(self):
        source = ROOT / ".chezmoiscripts/run_onchange_after_45-dock.sh.tmpl"
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            bindir = root / "bin"
            bindir.mkdir()
            log = root / "dockutil.log"
            dockutil = bindir / "dockutil"
            dockutil.write_text(f"#!/bin/sh\necho \"$*\" >> {log}\n")
            dockutil.chmod(0o755)
            uname = bindir / "uname"
            uname.write_text("#!/bin/sh\necho Darwin\n")
            uname.chmod(0o755)
            rendered = self.render_hook(source)
            rendered = rendered.replace("/System/Applications", str(root / "system-apps"))
            rendered = rendered.replace("/Applications", str(root / "apps"))
            hook = root / "dock.sh"
            hook.write_text(rendered)
            result = self.run_hook(hook, root, bindir)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("missing app bundle", result.stderr)
            self.assertFalse(log.exists())

    def test_touchid_ignores_commented_rule_but_accepts_active_rule(self):
        source = ROOT / ".chezmoiscripts/run_onchange_after_07-touchid-sudo.sh"
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            pam = root / "sudo_local"
            pam.write_text("# auth sufficient pam_tid.so\n")
            script = source.read_text().replace("/etc/pam.d/sudo_local", str(pam)).replace("/usr/lib/pam/pam_tid.so", str(root / "pam_tid.so"))
            (root / "pam_tid.so").touch()
            hook = root / "hook.sh"
            hook.write_text(script)
            bindir = root / "bin"
            bindir.mkdir()
            for name, body in (("uname", "echo Darwin"), ("sudo", 'exec "$@"'), ("defaults", "exit 0"), ("killall", "exit 0")):
                command = bindir / name
                command.write_text(f"#!/bin/sh\n{body}\n")
                command.chmod(0o755)
            result = self.run_hook(hook, root, bindir)
            self.assertEqual(result.returncode, 0)
            self.assertIn("auth       sufficient     pam_tid.so", pam.read_text())
            pam.write_text("auth sufficient /usr/lib/pam/pam_tid.so\n")
            result = self.run_hook(hook, root, bindir)
            self.assertEqual(result.returncode, 0)
            self.assertEqual(pam.read_text(), "auth sufficient /usr/lib/pam/pam_tid.so\n")


if __name__ == "__main__":
    unittest.main()
