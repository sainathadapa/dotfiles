#!/usr/bin/env python3

import json
import subprocess
import sys


class YabaiCommandError(RuntimeError):
    pass


def run_yabai(args):
    proc = subprocess.run(
        ["yabai", "-m", *args],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        check=False,
    )
    if proc.returncode != 0:
        message = proc.stderr.strip() or "yabai command failed"
        raise YabaiCommandError(message)
    return proc.stdout


def query_spaces(runner=run_yabai):
    return json.loads(runner(["query", "--spaces"]))


def label_spaces(spaces, runner=run_yabai):
    for space in spaces:
        index = str(space["index"])
        runner(["space", index, "--label", f"space-{index}"])


def visible_space_pairs(spaces):
    return [
        (str(space["label"]), str(space["display"]))
        for space in spaces
        if space.get("is-visible") is True
    ]


def swap_visible_spaces(runner=run_yabai):
    spaces = query_spaces(runner)
    label_spaces(spaces, runner)

    spaces = query_spaces(runner)
    visible_spaces = visible_space_pairs(spaces)

    if len(visible_spaces) != 2:
        raise RuntimeError(f"expected exactly 2 visible spaces, found {len(visible_spaces)}")

    first_label, first_display = visible_spaces[0]
    second_label, second_display = visible_spaces[1]

    runner(["space", first_label, "--display", second_display])
    runner(["space", second_label, "--display", first_display])
    runner(["space", first_label, "--move", second_label.split("-")[-1]])
    runner(["space", second_label, "--move", first_label.split("-")[-1]])

    return 0


def main():
    try:
        return swap_visible_spaces()
    except (YabaiCommandError, RuntimeError, json.JSONDecodeError) as exc:
        print(f"swap_spaces: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
