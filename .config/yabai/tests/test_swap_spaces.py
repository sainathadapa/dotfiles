import json
import pathlib
import sys
import unittest


YABAI_ROOT = pathlib.Path(__file__).resolve().parents[1]
SCRIPTS_DIR = YABAI_ROOT / "scripts"
sys.path.insert(0, str(SCRIPTS_DIR))

import swap_spaces


class FakeRunner:
    def __init__(self, responses):
        self.responses = list(responses)
        self.calls = []

    def __call__(self, args):
        self.calls.append(args)
        if self.responses:
            return self.responses.pop(0)
        return ""


class SwapSpacesTests(unittest.TestCase):
    def test_visible_space_pairs_uses_is_visible(self):
        spaces = [
            {"index": 1, "label": "space-1", "display": 1, "is-visible": True},
            {"index": 2, "label": "space-2", "display": 2, "is-visible": True},
            {"index": 3, "label": "space-3", "display": 1, "is-visible": False},
        ]

        self.assertEqual(
            [("space-1", "1"), ("space-2", "2")],
            swap_spaces.visible_space_pairs(spaces),
        )

    def test_visible_space_pairs_rejects_legacy_visible_key(self):
        spaces = [
            {"index": 1, "label": "space-1", "display": 1, "visible": 1},
            {"index": 2, "label": "space-2", "display": 2, "visible": 1},
        ]

        self.assertEqual([], swap_spaces.visible_space_pairs(spaces))

    def test_swap_visible_spaces_success(self):
        initial_spaces = [
            {"index": 1, "label": "", "display": 1, "is-visible": True},
            {"index": 9, "label": "", "display": 2, "is-visible": True},
        ]
        labeled_spaces = [
            {"index": 1, "label": "space-1", "display": 1, "is-visible": True},
            {"index": 9, "label": "space-9", "display": 2, "is-visible": True},
        ]
        runner = FakeRunner([
            json.dumps(initial_spaces),
            "",
            "",
            json.dumps(labeled_spaces),
            "",
            "",
            "",
            "",
        ])

        self.assertEqual(0, swap_spaces.swap_visible_spaces(runner))
        self.assertEqual(["query", "--spaces"], runner.calls[0])
        self.assertIn(["space", "1", "--label", "space-1"], runner.calls)
        self.assertIn(["space", "9", "--label", "space-9"], runner.calls)
        self.assertIn(["space", "space-1", "--display", "2"], runner.calls)
        self.assertIn(["space", "space-9", "--display", "1"], runner.calls)
        self.assertIn(["space", "space-1", "--move", "9"], runner.calls)
        self.assertIn(["space", "space-9", "--move", "1"], runner.calls)

    def test_swap_visible_spaces_rejects_one_visible_space(self):
        spaces = [
            {"index": 1, "label": "", "display": 1, "is-visible": True},
            {"index": 2, "label": "", "display": 1, "is-visible": False},
        ]
        runner = FakeRunner([
            json.dumps(spaces),
            "",
            "",
            json.dumps(spaces),
        ])

        with self.assertRaisesRegex(RuntimeError, "expected exactly 2 visible spaces"):
            swap_spaces.swap_visible_spaces(runner)

    def test_query_spaces_rejects_invalid_json(self):
        runner = FakeRunner(["not json"])

        with self.assertRaises(json.JSONDecodeError):
            swap_spaces.query_spaces(runner)


if __name__ == "__main__":
    unittest.main()
