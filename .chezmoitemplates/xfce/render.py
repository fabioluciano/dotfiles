"""Render managed Xfconf XML while retaining explicitly allowed runtime state."""

import sys
import xml.etree.ElementTree as ET
from copy import deepcopy
from pathlib import Path


def dynamic(channel, path):
    """Only these properties belong to the running desktop, not the source."""
    if channel == "xfce4-desktop":
        return path[:1] == ("last",) or (
            len(path) == 5
            and path[0] == "backdrop"
            and path[1].startswith("screen")
            and path[2].startswith("monitor")
            and path[3].startswith("workspace")
            and path[4] == "last-image"
        )
    if channel == "xfce4-panel":
        return (
            len(path) == 3
            and path[0] == "plugins"
            and path[1].startswith("plugin-")
            and path[2]
            in {"recent", "known-items", "known-legacy-items", "known-players"}
        )
    return False


def properties(root, path=()):
    for child in root:
        if child.tag == "property":
            child_path = (*path, child.attrib["name"])
            yield child_path, root, child
            yield from properties(child, child_path)


def semantic(node):
    """Property order is irrelevant; array value order remains significant."""
    attrs = dict(node.attrib)
    if attrs.get("type") == "double" and "value" in attrs:
        attrs["value"] = repr(float(attrs["value"]))
    props = sorted(
        (child.attrib["name"], semantic(child))
        for child in node
        if child.tag == "property"
    )
    values = tuple(semantic(child) for child in node if child.tag != "property")
    return (
        node.tag,
        tuple(sorted(attrs.items())),
        (node.text or "").strip(),
        tuple(props),
        values,
    )


def render(desired, current=None):
    target = ET.fromstring(desired)
    if target.tag != "channel":
        raise ValueError("Expected an Xfconf channel")
    if current is None:
        return desired
    live = ET.fromstring(current)
    if live.tag != "channel" or live.attrib != target.attrib:
        raise ValueError("Destination Xfconf channel does not match the source")
    channel = target.attrib["name"]
    # Replace whole runtime subtrees, including their absence in the destination.
    for path, parent, child in list(properties(target)):
        if dynamic(channel, path):
            parent.remove(child)
    target_props = {path: child for path, _, child in properties(target)}
    live_props = {path: child for path, _, child in properties(live)}
    for path, _, child in properties(live):
        if dynamic(channel, path) and not any(
            dynamic(channel, path[:end]) for end in range(1, len(path))
        ):
            if len(path) == 1:
                parent = target
            else:
                parent = target
                for end in range(1, len(path)):
                    ancestor_path = path[:end]
                    ancestor = target_props.get(ancestor_path)
                    if ancestor is None:
                        source = live_props[ancestor_path]
                        ancestor = ET.Element(
                            "property",
                            {
                                key: source.attrib[key]
                                for key in ("name", "type")
                                if key in source.attrib
                            },
                        )
                        parent.append(ancestor)
                        target_props[ancestor_path] = ancestor
                    parent = ancestor
            parent.append(deepcopy(child))
    if semantic(target) == semantic(live):
        # Keep the exact destination bytes: no formatting-only diff or rewrite.
        return current
    ET.indent(target, space="  ")
    return (
        '<?xml version="1.1" encoding="UTF-8"?>\n\n'
        + ET.tostring(target, encoding="unicode")
        + "\n"
    )


if __name__ == "__main__":
    try:
        current_xml = Path(sys.argv[2]).read_text(encoding="utf-8")
    except FileNotFoundError:
        current_xml = None
    sys.stdout.write(render(sys.argv[1], current_xml))
