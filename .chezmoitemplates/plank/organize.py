"""Keep pinned launchers and arrange nonempty categories with native separators."""

import ast
import configparser
import io
import sys
from pathlib import Path
from urllib.parse import unquote, urlsplit

CATEGORIES = (
    (
        "system",
        (
            "thunar.desktop",
            "vicinae.desktop",
            "xfce-settings-manager.desktop",
            "bitwarden.desktop",
        ),
    ),
    ("browsers", ("firefox.desktop", "google-chrome.desktop", "chromium.desktop")),
    (
        "communication",
        (
            "org.mozilla.Thunderbird.desktop",
            "whatsdesk.desktop",
            "org.telegram.desktop.desktop",
            "discord.desktop",
        ),
    ),
    (
        "productivity",
        (
            "org.gnome.Calendar.desktop",
            "org.gnome.Todo.desktop",
            "xfce4-notes.desktop",
            "obsidian.desktop",
        ),
    ),
    (
        "notes",
        (
            "joplin-desktop.desktop",
            "logseq.desktop",
        ),
    ),
    (
        "development",
        (
            "com.mitchellh.ghostty.desktop",
            "com.microsoft.VSCode.desktop",
            "dev.zed.Zed.desktop",
            "io.dbeaver.DBeaver.desktop",
            "bruno.desktop",
            "virt-manager.desktop",
            "io.podman_desktop.PodmanDesktop.desktop",
        ),
    ),
    (
        "media",
        (
            "spotify.desktop",
            "io.github.martinrotter.rssguard.desktop",
            "vlc.desktop",
        ),
    ),
    ("other", ()),
    ("files", ()),
)
SEPARATOR = "docklet://separator"
PREFIX = "dotfiles-separator-"
SEPARATOR_SECTION = "DockySeparatorPreferences"


def launcher(path):
    config = configparser.ConfigParser(interpolation=None)
    with path.open(encoding="utf-8") as stream:
        config.read_file(stream)
    for section in ("PlankDockItemPreferences", "PlankItemsDockItemPreferences"):
        if config.has_section(section):
            return config.get(section, "Launcher")
    raise ValueError(f"Missing launcher section: {path}")


def category(uri):
    parsed = urlsplit(uri)
    desktop = Path(unquote(parsed.path)).name
    for group, apps in CATEGORIES:
        if desktop in apps:
            return group, apps.index(desktop)
    if uri == "docklet://trash" or (
        parsed.scheme == "file" and not desktop.endswith(".desktop")
    ):
        return "files", 1 if uri == "docklet://trash" else 0
    return "other", 0


def use_space_style(path):
    """Enforce empty space only for separators owned by this configuration."""
    config = configparser.ConfigParser(interpolation=None)
    config.optionxform = str
    with path.open(encoding="utf-8") as stream:
        config.read_file(stream)
    if config.get(SEPARATOR_SECTION, "Style", fallback=None) == "2" and not config.get(
        SEPARATOR_SECTION, "CustomIcon", fallback=""
    ):
        return
    if not config.has_section(SEPARATOR_SECTION):
        config.add_section(SEPARATOR_SECTION)
    config.set(SEPARATOR_SECTION, "Style", "2")
    config.set(SEPARATOR_SECTION, "CustomIcon", "")
    stream = io.StringIO()
    config.write(stream, space_around_delimiters=False)
    path.write_text(stream.getvalue(), encoding="utf-8")


def organize(directory, ordering, defaults=(), additions=()):
    order = ast.literal_eval(ordering.removeprefix("@as "))
    if not isinstance(order, list) or not all(
        isinstance(name, str) and Path(name).name == name and name.endswith(".dockitem")
        for name in order
    ):
        raise ValueError("Expected a list of dockitem basenames")
    directory.mkdir(parents=True, exist_ok=True)
    existing = {
        path.name: launcher(path) for path in sorted(directory.glob("*.dockitem"))
    }
    # Only bootstrap the baseline dock when empty; additions opt into existing docks.
    if not existing and not order:
        for entry in defaults:
            name, _, target = entry.partition(":")
            uri = Path(target).as_uri()
            (directory / name).write_text(
                f"[PlankDockItemPreferences]\nLauncher={uri}\n"
            )
            existing[name] = uri
    existing_uris = set(existing.values())
    for entry in additions:
        name, _, target = entry.partition(":")
        uri = Path(target).as_uri()
        if name not in existing and uri not in existing_uris:
            (directory / name).write_text(
                f"[PlankDockItemPreferences]\nLauncher={uri}\n"
            )
            existing[name] = uri
            existing_uris.add(uri)
    names = list(dict.fromkeys([*order, *existing]))
    groups = {group: [] for group, _ in CATEGORIES}
    separators = []
    for name in names:
        if name not in existing:
            continue
        if existing[name] == SEPARATOR:
            if name.startswith(PREFIX):
                use_space_style(directory / name)
            separators.append(name)
        else:
            group, rank = category(existing[name])
            groups[group].append((rank, name))
    result = []
    for group, _ in CATEGORIES:
        members = [name for _, name in sorted(groups[group], key=lambda item: item[0])]
        if not members:
            continue
        if result:
            # Reuse existing separators, retaining their individual preferences.
            if separators:
                separator = separators.pop(0)
            else:
                separator = f"{PREFIX}{group}.dockitem"
                suffix = 1
                while (directory / separator).exists():
                    separator = f"{PREFIX}{group}-{suffix}.dockitem"
                    suffix += 1
                (directory / separator).write_text(
                    f"[PlankDockItemPreferences]\nLauncher={SEPARATOR}\n"
                    f"\n[{SEPARATOR_SECTION}]\nStyle=2\nCustomIcon=\n"
                )
            result.append(separator)
        result.extend(members)
    # Preserve surplus user separators instead of silently deleting their files.
    result.extend(separators)
    return result


if __name__ == "__main__":
    if len(sys.argv) == 3 and sys.argv[1] == "--spaces-only":
        for path in sorted(Path(sys.argv[2]).glob(f"{PREFIX}*.dockitem")):
            if launcher(path) == SEPARATOR:
                use_space_style(path)
                print(f"SPACE: {path.name}")
    else:
        boundary = sys.argv.index("--", 3) if "--" in sys.argv[3:] else len(sys.argv)
        print(
            repr(
                organize(
                    Path(sys.argv[1]),
                    sys.argv[2],
                    sys.argv[3:boundary],
                    sys.argv[boundary + 1 :],
                )
            )
        )
