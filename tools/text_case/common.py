"""Shared pieces of the mixed-case text pass (see convert.py)."""
import re
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]

# Macros whose string arguments are on-screen text.
TEXT_MACROS = {"text", "line", "cont", "para", "next", "page", "db", "dname", "li",
               "rawchar", "bt_trainer", "npctrade", "text_start"}
EXCLUDE = ["constants/charmap.asm", "data/pokemon/unown_words.asm", "mobile/", "lib/",
           "tools/", "engine/debug/", "macros/"]

LINE_RE = re.compile(r'^(\s*(?:[.\w]+:+\s*)?)(\w+)(\s.*)$')
STRING_RE = re.compile(r'"((?:[^"\\]|\\.)*)"')
WORD_RE = re.compile(r"[A-ZÉé][A-ZÉé']*")


def asm_files():
    for p in sorted(REPO.rglob("*.asm")):
        rel = p.relative_to(REPO).as_posix()
        if any(rel == e or rel.startswith(e) for e in EXCLUDE):
            continue
        yield p, rel


def text_strings(line):
    """Yield (start, end) spans of on-screen string literals in an asm line."""
    code = line.split(";", 1)[0]
    m = LINE_RE.match(code)
    if not m or m.group(2) not in TEXT_MACROS:
        return
    offset = m.start(3)
    for s in STRING_RE.finditer(m.group(3)):
        yield offset + s.start(1), offset + s.end(1)


def outside_tags(s):
    """Yield (start, end) spans of s outside <...> charmap tags and {...} interpolations."""
    i = 0
    for t in re.finditer(r"<[^>]*>|\{[^}]*\}", s):
        yield i, t.start()
        i = t.end()
    yield i, len(s)
