"""Hermetic signature checks; no hardware prompts or real user keys."""
import os
from pathlib import Path
import re
import subprocess
import tempfile
import unittest

SIGNER = Path(__file__).resolve().parents[2] / "private_dot_local/bin/executable_git-ssh-sign"


class SigningTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name)
        (self.home / ".ssh").mkdir()
        self.env = dict(os.environ, HOME=str(self.home))
        self.private_key = self.home / "fixture"
        subprocess.run(["/usr/bin/ssh-keygen", "-q", "-t", "ed25519", "-N", "", "-f", str(self.private_key)], check=True)
        public = self.private_key.with_suffix(".pub").read_text()
        (self.home / ".ssh/yubikey.pub").write_text(public)
        self.allowed = self.home / "allowed"
        self.allowed.write_text("test@example.com " + public)
        self.payload = b"tree example\nauthor example\n\nmessage\x00\xff\n" * 4096

    def sign(self, key, source="-"):
        return subprocess.run(["bash", str(SIGNER), "-Y", "sign", "-n", "git", "-f", str(key), str(source)], env=self.env, input=self.payload, capture_output=True)

    def verify(self, signature, payload):
        path = self.home / "signature"
        path.write_bytes(signature)
        return subprocess.run(["bash", str(SIGNER), "-Y", "verify", "-n", "git", "-f", str(self.allowed), "-I", "test@example.com", "-s", str(path)], env=self.env, input=payload, capture_output=True)

    def test_explicit_key_remains_usable_and_tampering_is_rejected(self):
        result = self.sign(self.private_key)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.verify(result.stdout, self.payload).returncode, 0)
        self.assertNotEqual(self.verify(result.stdout, self.payload + b"tampered").returncode, 0)

    def test_yubikey_priority_and_fail_closed_without_fallback_key(self):
        agent = subprocess.run(["/usr/bin/ssh-agent", "-s"], check=True, capture_output=True, text=True).stdout
        self.env.update(dict(re.findall(r"(SSH_AUTH_SOCK|SSH_AGENT_PID)=([^;]+)", agent)))
        self.addCleanup(lambda: subprocess.run(["/usr/bin/ssh-agent", "-k"], env=self.env, capture_output=True, check=True))
        subprocess.run(["/usr/bin/ssh-add", str(self.private_key)], env=self.env, check=True, capture_output=True)
        commands = self.home / "bin"
        commands.mkdir()
        # Only discovery is simulated: signatures still come from a real agent.
        for name, body in {"gpgconf": 'printf "%s\\n" "$SSH_AUTH_SOCK"', "gpg-connect-agent": "exit 0"}.items():
            command = commands / name
            command.write_text("#!/bin/sh\n" + body + "\n")
            command.chmod(0o700)
        self.env["PATH"] = str(commands) + os.pathsep + self.env["PATH"]
        key = self.home / ".ssh/yubikey.pub"
        # An invalid fallback must not be tried when the primary works.
        fallback = self.home / ".ssh/touchid.pub"
        fallback.write_text("invalid public key\n")
        for source in ("-", self.home / "commit-payload"):
            with self.subTest(source=str(source)):
                if source != "-":
                    source.write_bytes(self.payload)
                result = self.sign(key, source)
                self.assertEqual(result.returncode, 0, result.stderr)
                signature = result.stdout if source == "-" else Path(str(source) + ".sig").read_bytes()
                self.assertEqual(self.verify(signature, self.payload).returncode, 0)
                if source != "-":
                    Path(str(source) + ".sig").unlink()
        fallback.unlink()
        # A stale agent/card listing must not yield an unsigned or partial commit.
        subprocess.run(["/usr/bin/ssh-add", "-D"], env=self.env, check=True, capture_output=True)
        for source in ("-", self.home / "commit-payload"):
            with self.subTest(source=str(source)):
                result = self.sign(key, source)
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(result.stdout, b"")
                self.assertFalse((self.home / "commit-payload.sig").exists())

    def test_linux_fallback_uses_fingerprint_authorization(self):
        commands = self.home / "bin_linux"
        commands.mkdir()
        uname = commands / "uname"
        uname.write_text("#!/bin/sh\necho Linux\n")
        uname.chmod(0o700)
        fprintd = commands / "fprintd-verify"
        fprintd.write_text("#!/bin/sh\nexit 0\n")
        fprintd.chmod(0o700)
        gpgconf = commands / "gpgconf"
        gpgconf.write_text("#!/bin/sh\nexit 1\n")
        gpgconf.chmod(0o700)

        linux_key = self.home / ".ssh/linux_fingerprint"
        subprocess.run(["/usr/bin/ssh-keygen", "-q", "-t", "ed25519", "-N", "", "-f", str(linux_key)], check=True)
        linux_pub = linux_key.with_suffix(".pub").read_text()
        (self.home / "allowed").write_text("test@example.com " + linux_pub)

        env = dict(self.env, PATH=str(commands) + os.pathsep + self.env["PATH"])
        result = subprocess.run(["bash", str(SIGNER), "-Y", "sign", "-n", "git", "-f", str(self.home / ".ssh/yubikey.pub"), "-"], env=env, input=self.payload, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.verify(result.stdout, self.payload).returncode, 0)

        # When fingerprint verification fails, signing fails
        fprintd.write_text("#!/bin/sh\nexit 1\n")
        result = subprocess.run(["bash", str(SIGNER), "-Y", "sign", "-n", "git", "-f", str(self.home / ".ssh/yubikey.pub"), "-"], env=env, input=self.payload, capture_output=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(result.stdout, b"")

if __name__ == "__main__":
    unittest.main()
