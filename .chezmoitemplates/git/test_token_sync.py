"""Hermetic behavioral coverage for tmux token synchronization."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
import uuid

SYNC = Path(__file__).resolve().parents[2] / "private_dot_local/bin/executable_tmux-tokens-sync"
ZSHENV = Path(__file__).resolve().parents[2] / "private_dot_zshenv.tmpl"


class TokenSyncTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(dir="/tmp")
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name)
        config = self.home / ".config/zsh"
        config.mkdir(parents=True, mode=0o700)
        self.token_file = config / "tokens.zsh"
        self.socket = str(self.home / f"tmux-{uuid.uuid4().hex[:8]}.sock")
        self.env = dict(os.environ, HOME=str(self.home), XDG_CONFIG_HOME=str(self.home / ".config"),
                        ZDOTDIR=str(self.home), PATH=os.environ["PATH"], TMUX_TMPDIR=str(self.home))
        for name in ("GITHUB_TOKEN", "GEMINI_API_KEY", "GOOGLE_API_KEY", "TMUX"):
            self.env.pop(name, None)
        (self.home / ".zshenv").write_text(self.loader_source())
        (self.home / ".zshenv").chmod(0o600)
        self.tmux_config = self.home / "tmux.conf"
        self.tmux_config.write_text(f"run-shell 'zsh {SYNC}'\n")

    def loader_source(self):
        source = ZSHENV.read_text()
        return source[source.index("_ZSH_TOKEN_VARS=("):source.index("if [[ -o interactive")]

    def start_first_session(self):
        return subprocess.run(["tmux", "-S", self.socket, "-f", str(self.tmux_config), "new-session", "-d"],
                              env=self.env, capture_output=True, text=True)

    def stop_server(self):
        subprocess.run(["tmux", "-S", self.socket, "kill-server"], env=self.env,
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    def server_env(self, name):
        result = subprocess.run(["tmux", "-S", self.socket, "show-environment", "-g", name],
                                env=self.env, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        return result.stdout.rstrip("\n").split("=", 1)[1]

    def test_first_session_sync_preserves_quotes_and_newlines(self):
        expected = "abc'def \"quoted\"\nnext line"
        value = "'" + expected.replace("'", "'\\''") + "'"
        self.token_file.write_text("export GITHUB_TOKEN=" + value + "\n")
        self.token_file.chmod(0o600)
        result = self.start_first_session()
        self.addCleanup(self.stop_server)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.server_env("GITHUB_TOKEN"), expected)

    def test_google_alias_fills_missing_value_and_preserves_explicit_pair(self):
        self.token_file.write_text("export GEMINI_API_KEY='gemini-explicit'\nexport GOOGLE_API_KEY='google-explicit'\n")
        self.token_file.chmod(0o600)
        result = self.start_first_session()
        self.addCleanup(self.stop_server)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.server_env("GEMINI_API_KEY"), "gemini-explicit")
        self.assertEqual(self.server_env("GOOGLE_API_KEY"), "google-explicit")

    def test_google_alias_fills_missing_destination(self):
        self.token_file.write_text("export GEMINI_API_KEY='gemini-only'\n")
        self.token_file.chmod(0o600)
        result = self.start_first_session()
        self.addCleanup(self.stop_server)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.server_env("GEMINI_API_KEY"), "gemini-only")
        self.assertEqual(self.server_env("GOOGLE_API_KEY"), "gemini-only")

    def test_unsafe_token_file_is_rejected(self):
        marker = self.home / "executed"
        self.token_file.write_text(f"touch {marker}\nexport GITHUB_TOKEN='unsafe'\n")
        self.token_file.chmod(0o644)
        result = self.start_first_session()
        self.addCleanup(self.stop_server)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(marker.exists())
        result = subprocess.run(["tmux", "-S", self.socket, "show-environment", "-g", "GITHUB_TOKEN"],
                                env=self.env, capture_output=True)
        self.assertNotEqual(result.returncode, 0)



if __name__ == "__main__":
    unittest.main()
