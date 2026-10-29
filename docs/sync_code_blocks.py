"""Keep code shown in the docs identical to the real files.

Every block in a doc written as

    **File:** `ml-training/src/crop_ml/data.py`

    ```python
    ...
    ```

is replaced with the current content of that file (path relative to the repo root).

Run from the repo root:
    python3 docs/sync_code_blocks.py            # update all docs/*.md in place
    python3 docs/sync_code_blocks.py --check    # exit 1 if any doc is out of date (for CI)
"""

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
# Body = whole lines that do not start with ``` (may be empty), then the closing fence.
BLOCK = re.compile(r"(\*\*File:\*\* `(?P<path>[^`]+)`\n\n```(?P<lang>[\w-]*)\n)(?P<body>(?:(?!```).*\n)*)(```)")


def sync(text: str) -> tuple[str, list[str]]:
    missing: list[str] = []

    def repl(m: re.Match) -> str:
        path = ROOT / m["path"]
        if not path.is_file():
            missing.append(m["path"])
            return m.group(0)
        return f"{m.group(1)}{path.read_text().rstrip()}\n{m.group(5)}"

    return BLOCK.sub(repl, text), missing


def _self_test() -> None:
    """An empty block must not swallow text up to the next code fence."""
    doc = "**File:** `.gitignore`\n\n```python\n```\nKEEP ME\n```text\nx\n```\n"
    out, _ = sync(doc)
    assert "KEEP ME" in out and out.count("```") == 4, "sync_code_blocks self-test failed"


def main() -> int:
    _self_test()
    check = "--check" in sys.argv
    stale = []
    for doc in sorted((ROOT / "docs").glob("*.md")):
        old = doc.read_text()
        new, missing = sync(old)
        if missing:  # e.g. docs for phases whose code is not in the repo yet
            print(f"{doc.name}: {len(missing)} block(s) left as-is (file not in repo, e.g. {missing[0]})")
        if new != old:
            stale.append(doc.name)
            if not check:
                doc.write_text(new)
    verb = "out of date" if check else "updated"
    print(f"{len(stale)} doc(s) {verb}: {', '.join(stale) or '-'}")
    return 1 if check and stale else 0


if __name__ == "__main__":
    sys.exit(main())
