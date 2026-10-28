"""Non-mutating dock organization and startup regression tests."""

import configparser
import json
import os
import subprocess
import tempfile
import unittest
from pathlib import Path

from organize import PREFIX, SEPARATOR, SEPARATOR_SECTION, launcher, organize

ROOT = Path(__file__).resolve().parents[2]


def write_item(directory, name, uri):
    path = directory / f"{name}.dockitem"
    path.write_text(f"[PlankDockItemPreferences]\nLauncher={uri}\n")
    return path.name


class OrganizeTests(unittest.TestCase):
    def setUp(self):
        self.scratch = tempfile.TemporaryDirectory(prefix="plank-test-")
        self.addCleanup(self.scratch.cleanup)
        self.directory = Path(self.scratch.name)

    def test_categories_preserve_aliases_and_existing_files(self):
        apps = (
            ("custom-ghostty", "com.mitchellh.ghostty.desktop"),
            ("firefox", "firefox.desktop"),
            ("files", "thunar.desktop"),
            ("telegram", "org.telegram.desktop.desktop"),
            ("notes", "obsidian.desktop"),
            ("spotify", "spotify.desktop"),
            ("bitwarden", "bitwarden.desktop"),
        )
        names = [
            write_item(self.directory, name, f"file:///apps/{app}")
            for name, app in apps
        ]
        names.append(write_item(self.directory, "trash", "docklet://trash"))
        before = {path.name: path.read_bytes() for path in self.directory.iterdir()}
        order = organize(self.directory, repr(names))
        expected = [names[index] for index in (2, 6, 1, 3, 4, 0, 5, 7)]
        self.assertEqual(
            [name for name in order if launcher(self.directory / name) != SEPARATOR],
            expected,
        )
        self.assertEqual(
            sum(launcher(self.directory / name) == SEPARATOR for name in order), 6
        )
        self.assertEqual(len(order), len(set(order)))
        self.assertNotEqual(launcher(self.directory / order[0]), SEPARATOR)
        self.assertNotEqual(launcher(self.directory / order[-1]), SEPARATOR)
        for name, contents in before.items():
            self.assertEqual((self.directory / name).read_bytes(), contents)
        self.assertEqual(organize(self.directory, repr(order)), order)
        self.assertEqual(len(list(self.directory.glob("*.dockitem"))), len(order))
        for name in order:
            if launcher(self.directory / name) == SEPARATOR:
                config = configparser.ConfigParser(interpolation=None)
                config.read(self.directory / name)
                self.assertEqual(config.get(SEPARATOR_SECTION, "Style"), "2")
                self.assertEqual(config.get(SEPARATOR_SECTION, "CustomIcon"), "")

    def test_one_group_has_no_separators(self):
        name = write_item(self.directory, "firefox", "file:///apps/firefox.desktop")
        self.assertEqual(organize(self.directory, repr([name])), [name])

    def test_empty_dock_and_gvariant_empty_array(self):
        self.assertEqual(organize(self.directory, "@as []"), [])
        self.assertEqual(list(self.directory.iterdir()), [])

    def test_bootstrap_encodes_uri_and_does_not_add_apps_to_existing_dock(self):
        defaults = ["downloads.dockitem:/home/test/Downloads with spaces"]
        order = organize(self.directory, "[]", defaults)
        self.assertEqual(
            launcher(self.directory / order[0]),
            "file:///home/test/Downloads%20with%20spaces",
        )
        self.assertEqual(
            organize(self.directory, repr(order), ["new.dockitem:/new/app.desktop"]),
            order,
        )
        self.assertFalse((self.directory / "new.dockitem").exists())

    def test_unknown_app_is_kept_before_folders(self):
        folder = write_item(self.directory, "folder", "file:///home/test/Downloads")
        unknown = write_item(self.directory, "unknown", "file:///apps/new.desktop")
        order = organize(self.directory, repr([folder, unknown]))
        self.assertLess(order.index(unknown), order.index(folder))

    def test_existing_separator_preferences_are_preserved(self):
        one = write_item(self.directory, "browser", "file:///apps/firefox.desktop")
        two = write_item(
            self.directory, "terminal", "file:///apps/com.mitchellh.ghostty.desktop"
        )
        separator = write_item(self.directory, "custom-separator", SEPARATOR)
        path = self.directory / separator
        path.write_text(path.read_text() + "Style=2\n")
        original = path.read_bytes()
        self.assertEqual(
            organize(self.directory, repr([one, two, separator])), [one, separator, two]
        )
        self.assertEqual(path.read_bytes(), original)

    def test_unsafe_order_fails_before_writes(self):
        for ordering in ("['../bad.dockitem']", "{'bad': 1}", "[4]", "not a list"):
            with (
                self.subTest(ordering=ordering),
                self.assertRaises((ValueError, SyntaxError)),
            ):
                organize(self.directory, ordering)
        self.assertEqual(list(self.directory.iterdir()), [])

    def test_managed_separators_become_spaces_without_changing_other_preferences(self):
        one = write_item(self.directory, "browser", "file:///apps/firefox.desktop")
        two = write_item(self.directory, "notes", "file:///apps/obsidian.desktop")
        separator = write_item(self.directory, f"{PREFIX}notes", SEPARATOR)
        path = self.directory / separator
        path.write_text(
            path.read_text()
            + f"\n[{SEPARATOR_SECTION}]\nStyle=0\nCustomIcon=/line.svg\nInvertColor=true\n"
        )
        order = organize(self.directory, repr([one, separator, two]))
        config = configparser.ConfigParser(interpolation=None)
        config.read(path)
        self.assertEqual(config.get(SEPARATOR_SECTION, "Style"), "2")
        self.assertEqual(config.get(SEPARATOR_SECTION, "CustomIcon"), "")
        self.assertEqual(config.get(SEPARATOR_SECTION, "InvertColor"), "true")
        self.assertEqual(launcher(path), SEPARATOR)
        contents = path.read_bytes()
        self.assertEqual(organize(self.directory, repr(order)), order)
        self.assertEqual(path.read_bytes(), contents)

    def test_managed_legacy_separator_gains_space_preferences(self):
        separator = write_item(self.directory, f"{PREFIX}browsers", SEPARATOR)
        organize(self.directory, repr([separator]))
        config = configparser.ConfigParser(interpolation=None)
        config.read(self.directory / separator)
        self.assertEqual(config.get(SEPARATOR_SECTION, "Style"), "2")
        self.assertEqual(config.get(SEPARATOR_SECTION, "CustomIcon"), "")

    def test_new_category_does_not_overwrite_a_reused_separator_name(self):
        one = write_item(self.directory, "browser", "file:///apps/firefox.desktop")
        two = write_item(self.directory, "trash", "docklet://trash")
        order = organize(self.directory, repr([one, two]))
        existing = self.directory / f"{PREFIX}files.dockitem"
        original = existing.read_bytes()
        extra = write_item(self.directory, "workspaces", "docklet://workspaces")
        result = organize(self.directory, repr([*order, extra]))
        self.assertIn(extra, result)
        self.assertEqual(existing.read_bytes(), original)
        self.assertEqual(
            sum(launcher(self.directory / name) == SEPARATOR for name in result), 2
        )
        self.assertEqual(organize(self.directory, repr(result)), result)

    def test_spaces_only_does_not_reorder_or_touch_apps(self):
        app = write_item(self.directory, "workspaces", "docklet://workspaces")
        original = (self.directory / app).read_bytes()
        separator = write_item(self.directory, f"{PREFIX}files", SEPARATOR)
        subprocess.run(
            [
                "/usr/bin/python3",
                "-B",
                str(ROOT / ".chezmoitemplates/plank/organize.py"),
                "--spaces-only",
                str(self.directory),
            ],
            capture_output=True,
            check=True,
        )
        config = configparser.ConfigParser(interpolation=None)
        config.read(self.directory / separator)
        self.assertEqual(config.get(SEPARATOR_SECTION, "Style"), "2")
        self.assertEqual((self.directory / app).read_bytes(), original)
        self.assertEqual(len(list(self.directory.glob("*.dockitem"))), 2)

    def test_primary_startup_and_organize_only_hook(self):
        fakebin = self.directory / "bin"
        fakebin.mkdir()
        log = self.directory / "commands.jsonl"
        stub = """#!/usr/bin/python3
import json, os, pathlib, sys
name = pathlib.Path(sys.argv[0]).name
with open(os.environ["PLANK_TEST_LOG"], "a") as stream:
    stream.write(json.dumps([name, *sys.argv[1:]]) + "\\n")
if name == "xrandr":
    print("DP-0 connected 1080x1920+0+0\\nDP-2 connected primary 2560x1440+1080+0")
elif name == "pgrep":
    sys.exit(1)
elif name == "gsettings" and sys.argv[1] == "get":
    print("['firefox.dockitem']")
"""
        for name in ("xrandr", "gsettings", "pgrep", "setsid", "plank"):
            path = fakebin / name
            path.write_text(stub)
            path.chmod(0o755)
        environment = {
            **os.environ,
            "PATH": f"{fakebin}:{os.environ['PATH']}",
            "PLANK_TEST_LOG": str(log),
            "HOME": str(self.directory),
        }
        subprocess.run(
            ["bash", str(ROOT / "private_dot_local/bin/executable_plank-multidock")],
            env=environment,
            check=True,
        )
        commands = [json.loads(line) for line in log.read_text().splitlines()]
        self.assertEqual(
            [cmd for cmd in commands if cmd[0] == "setsid"],
            [["setsid", "-f", "plank", "-n", "dock1"]],
        )
        self.assertIn(
            [
                "gsettings",
                "set",
                "net.launchpad.plank.dock.settings:/net/launchpad/plank/docks/dock1/",
                "monitor",
                "DP-2",
            ],
            commands,
        )
        source = ROOT / ".chezmoiscripts/run_after_59-plank.sh.tmpl"
        rendered = subprocess.run(
            [
                "chezmoi", "execute-template", "--override-data",
                '{"chezmoi":{"os":"linux","osRelease":{"id":"arch"}}}',
            ],
            input=source.read_text(),
            capture_output=True,
            text=True,
            check=True,
            cwd=ROOT,
        ).stdout
        separator_lib = self.directory / "separator.so"
        separator_lib.touch()
        rendered = rendered.replace(
            "/usr/lib/plank/docklets/libdocklet-separator.so", str(separator_lib)
        )
        launchers = self.directory / ".config/plank/dock1/launchers"
        launchers.mkdir(parents=True)
        write_item(launchers, "firefox", "file:///apps/firefox.desktop")
        log.write_text("")
        subprocess.run(
            ["bash", "-s", "--", "--organize-only"],
            input=rendered,
            text=True,
            env=environment,
            check=True,
        )
        commands = [json.loads(line) for line in log.read_text().splitlines()]
        sets = [cmd for cmd in commands if cmd[:2] == ["gsettings", "set"]]
        self.assertEqual(
            {cmd[3] for cmd in sets},
            {
                "monitor",
                "active-display",
                "anchor-files",
                "anchor-docklets",
                "dock-items",
            },
        )
        self.assertTrue(all("dock1/" in cmd[2] for cmd in sets))
        self.assertFalse((self.directory / ".config/plank/dock2").exists())


if __name__ == "__main__":
    unittest.main()
