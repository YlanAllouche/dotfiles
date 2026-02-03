#!/usr/bin/env python3

import json
import os
import subprocess
from pathlib import Path

TYPE_GLYPHS = {"work": "", "study": "󰼅"}
STATUS_GLYPHS = {"focus": "", "active": "󱐋"}


def get_sort_priority(entry):
    status = entry.get("status", "")
    entry_type = entry.get("type", "")

    if status == "focus":
        status_priority = 0
    elif status == "active":
        status_priority = 1
    else:
        status_priority = 2

    type_priority = 0 if entry_type == "work" else 1

    return (status_priority, type_priority)


def format_entry(entry):
    type_glyph = TYPE_GLYPHS.get(entry.get("type", ""), "")
    status = entry.get("status", "")

    status_glyph = STATUS_GLYPHS.get(status, "")

    summary = entry.get("summary", "")
    workspace = entry.get("workspace", "")
    file_path = entry.get("file", "")

    display = f"{type_glyph} {status_glyph} {summary}".strip()

    return display, workspace, file_path


def main():
    json_path = Path.home() / "share" / "_tmp" / "initiatives.json"

    with open(json_path, "r") as f:
        entries = json.load(f)

    filtered_entries = [
        e for e in entries if e.get("workspace") and e.get("workspace").strip()
    ]

    sorted_entries = sorted(filtered_entries, key=get_sort_priority)

    fzf_lines = []
    workspace_map = {}
    file_map = {}

    for entry in sorted_entries:
        display, workspace, file_path = format_entry(entry)
        fzf_lines.append(display)
        workspace_map[display] = workspace
        file_map[display] = file_path

    import tempfile

    with tempfile.NamedTemporaryFile(mode="w", delete=False, suffix=".json") as tf:
        json.dump(file_map, tf)
        temp_map_file = tf.name

    fzf_input = "\n".join(fzf_lines)

    preview_cmd = f"""
    python3 -c "
import json, sys
from pathlib import Path

with open('{temp_map_file}', 'r') as f:
    file_map = json.load(f)

selected = sys.argv[1] if len(sys.argv) > 1 else ''
file_path = file_map.get(selected, '')

if file_path:
    full_path = Path.home() / 'share' / file_path
    print(str(full_path))
" {{}} | xargs -I{{}} bat --color=always --style=numbers --language=markdown {{}}
    """

    temp_selection_file = "/tmp/fzf-selected-entry"

    try:
        result = subprocess.run(
            [
                "fzf",
                "--ansi",
                "--height",
                "100%",
                "--preview",
                preview_cmd,
                "--preview-window",
                "right:60%:wrap",
                "--expect",
                "ctrl-o",
            ],
            input=fzf_input,
            text=True,
            capture_output=True,
        )

        lines = result.stdout.strip().split("\n")
        key_pressed = lines[0] if lines else ""

        if key_pressed == "ctrl-o" and len(lines) > 1:
            selected = lines[1]
        else:
            selected = key_pressed
            key_pressed = ""

        if result.returncode == 0:
            if key_pressed == "ctrl-o":
                file_path = file_map.get(selected, "")

                if file_path:
                    full_path = Path.home() / "share" / file_path
                    subprocess.run(
                        [
                            "nvim",
                            "--server",
                            str(Path.home() / ".cache" / "nvim" / "share.pipe"),
                            "--remote-send",
                            f":e {full_path}<CR>",
                        ]
                    )
            else:
                workspace = workspace_map.get(selected)

                if workspace:
                    workspace_path = Path.home() / "workspaces" / workspace
                    subprocess.run(
                        ["/home/ylan/.local/bin/tmux-sessionizer", str(workspace_path)]
                    )

    except FileNotFoundError:
        print("Error: fzf or tmux-sessionizer not found")
        return 1
    finally:
        try:
            os.unlink(temp_map_file)
        except:
            pass
        try:
            os.unlink(temp_selection_file)
        except:
            pass


if __name__ == "__main__":
    main()
