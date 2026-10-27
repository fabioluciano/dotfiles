"""Regression tests; run with /usr/bin/python3 -B this_file.py."""

import subprocess
import tempfile
import unittest
import xml.etree.ElementTree as ET
from pathlib import Path

from render import dynamic, properties, render, semantic

ROOT = Path(__file__).resolve().parent


def xml(channel, body):
    return f'<channel name="{channel}" version="1.0">{body}</channel>'


class RenderTests(unittest.TestCase):
    def test_bootstrap_keeps_source(self):
        for source in ROOT.glob("*.xml"):
            with self.subTest(source=source.name):
                desired = source.read_text()
                self.assertEqual(render(desired), desired)

    def test_all_channels_are_stable_after_xfce_serialization(self):
        for source in ROOT.glob("*.xml"):
            with self.subTest(source=source.name):
                desired = source.read_text()
                tree = ET.fromstring(desired)
                for node in tree.iter():
                    props = [child for child in node if child.tag == "property"]
                    values = [child for child in node if child.tag != "property"]
                    node[:] = values + list(reversed(props))
                    if node.get("type") == "double" and node.get("value") == "0.2":
                        node.set("value", "0.20000000000000001")
                live = ET.tostring(tree, encoding="unicode")
                self.assertEqual(render(desired, live), live)

    def test_desktop_preserves_wallpaper_and_window_geometry(self):
        desired = (ROOT / "xfce4-desktop.xml").read_text()
        tree = ET.fromstring(desired)
        tree.find("./property[@name='last']/property").set("value", "999")
        for node in tree.findall(".//property[@name='last-image']"):
            node.set("value", '/wallpapers/a & b "new".png')
        live = ET.tostring(tree, encoding="unicode")
        self.assertEqual(render(desired, live), live)

    def test_runtime_fields_can_be_added_or_absent(self):
        desired = xml(
            "xfce4-panel",
            '<property name="plugins" type="empty">'
            '<property name="plugin-22" type="string" value="whiskermenu"/>'
            "</property>",
        )
        live = desired.replace(
            'value="whiskermenu"/>',
            'value="whiskermenu">'
            '<property name="recent" type="array">'
            '<value type="string" value="new.desktop"/>'
            "</property></property>",
        )
        self.assertEqual(render(desired, live), live)
        self.assertEqual(render(live, desired), desired)

    def test_panel_preserves_all_known_runtime_fields(self):
        desired = (ROOT / "xfce4-panel.xml").read_text()
        tree = ET.fromstring(desired)
        for name in ("recent", "known-items", "known-legacy-items", "known-players"):
            for node in tree.findall(f".//property[@name='{name}']"):
                if node.get("type") == "array":
                    node[:] = [ET.Element("value", type="string", value="new-entry")]
                else:
                    node.set("value", "new-player")
        live = ET.tostring(tree, encoding="unicode")
        self.assertEqual(render(desired, live), live)

    def test_managed_changes_are_not_hidden(self):
        for source, name in (
            ("xsettings.xml", "ThemeName"),
            ("xfce4-panel.xml", "size"),
            ("xfce4-desktop.xml", "backdrop-cycle-period"),
            ("displays.xml", "Resolution"),
            ("xfwm4.xml", "theme"),
        ):
            with self.subTest(source=source):
                desired = (ROOT / source).read_text()
                tree = ET.fromstring(desired)
                tree.find(f".//property[@name='{name}']").set("value", "changed")
                live = ET.tostring(tree, encoding="unicode")
                result = render(desired, live)
                self.assertNotEqual(result, live)
                self.assertEqual(
                    semantic(ET.fromstring(result)), semantic(ET.fromstring(desired))
                )
                self.assertEqual(render(desired, result), result)

    def test_managed_change_preserves_runtime_state(self):
        desired = (ROOT / "xfce4-panel.xml").read_text()
        tree = ET.fromstring(desired)
        tree.find(".//property[@name='size']").set("value", "99")
        recent = tree.find(".//property[@name='recent']")
        recent[:] = [ET.Element("value", type="string", value="keep-me.desktop")]
        result = ET.fromstring(render(desired, ET.tostring(tree, encoding="unicode")))
        self.assertEqual(result.find(".//property[@name='size']").get("value"), "30")
        self.assertEqual(
            result.find(".//property[@name='recent']/value").get("value"),
            "keep-me.desktop",
        )

    def test_array_order_is_not_ignored(self):
        desired = xml(
            "test",
            '<property name="order" type="array">'
            '<value type="int" value="1"/><value type="int" value="2"/>'
            "</property>",
        )
        live = (
            desired.replace('value="1"', 'value="3"')
            .replace('value="2"', 'value="1"')
            .replace('value="3"', 'value="2"')
        )
        self.assertNotEqual(render(desired, live), live)

    def test_comment_changes_do_not_create_diffs(self):
        desired = xml("test", '<property name="size" type="int" value="30"/>')
        live = desired.replace("<property", "<!-- Xfce runtime -->\n<property")
        self.assertEqual(render(desired, live), live)

    def test_unknown_fields_are_not_silently_preserved(self):
        desired = xml("test", "")
        live = xml("test", '<property name="unexpected" type="bool" value="true"/>')
        self.assertNotEqual(render(desired, live), live)

    def test_invalid_destination_fails_closed(self):
        desired = xml("test", "")
        for live in ("broken", xml("other", ""), "<not-a-channel/>"):
            with (
                self.subTest(live=live),
                self.assertRaises((ValueError, ET.ParseError)),
            ):
                render(desired, live)

    def test_real_templates_against_isolated_destination(self):
        repo = ROOT.parent.parent
        wrappers = repo / "private_dot_config/xfce4/xfconf/private_xfce-perchannel-xml"
        with tempfile.TemporaryDirectory(prefix="xfce-xml-") as destination:
            targets = Path(destination) / ".config/xfce4/xfconf/xfce-perchannel-xml"
            targets.mkdir(parents=True)
            for wrapper in sorted(wrappers.glob("*.tmpl")):
                with self.subTest(wrapper=wrapper.name):
                    command = [
                        "chezmoi",
                        "--destination",
                        destination,
                        "execute-template",
                    ]

                    def execute(command=command, wrapper=wrapper):
                        return subprocess.run(
                            command,
                            input=wrapper.read_text(),
                            text=True,
                            capture_output=True,
                            check=True,
                            cwd=repo,
                        ).stdout

                    # Bootstrap is rendered into scratch, never the actual HOME.
                    desired = execute()
                    tree = ET.fromstring(desired)
                    for node in tree.iter():
                        if node.get("name") == "last-image":
                            node.set("value", "/runtime/new & wallpaper.png")
                        if node.get("name") in {"known-items", "recent"}:
                            node[:] = [
                                ET.Element("value", type="string", value="runtime")
                            ]
                        if node.get("type") == "double" and node.get("value") == "0.2":
                            node.set("value", "0.20000000000000001")
                        props = [child for child in node if child.tag == "property"]
                        values = [child for child in node if child.tag != "property"]
                        node[:] = values + list(reversed(props))
                    live = ET.tostring(tree, encoding="unicode")
                    target = targets / wrapper.name.removesuffix(".tmpl")
                    target.write_text(live)
                    self.assertEqual(execute(), live)
                    managed = next(
                        node
                        for path, _, node in properties(tree)
                        if "value" in node.attrib
                        and not dynamic(tree.attrib["name"], path)
                    )
                    managed.set("value", "intentional-test-difference")
                    changed = ET.tostring(tree, encoding="unicode")
                    target.write_text(changed)
                    corrected = execute()
                    self.assertNotEqual(corrected, changed)
                    target.write_text(corrected)
                    self.assertEqual(execute(), corrected)
                    tree.set("version", "wrong")
                    target.write_text(ET.tostring(tree, encoding="unicode"))
                    with self.assertRaises(subprocess.CalledProcessError):
                        execute()


if __name__ == "__main__":
    unittest.main()
