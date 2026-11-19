import sys, collections
sys.path.insert(0, __import__('os').path.dirname(__file__))
from common import *
c = collections.Counter()
for p, rel in asm_files():
    for line in p.read_text(encoding="utf-8").splitlines():
        for a, b in text_strings(line):
            s = line[a:b]
            for x, y in outside_tags(s):
                for w in WORD_RE.finditer(s[x:y]):
                    if len(w.group().rstrip("'")) >= 2:
                        c[w.group()] += 1
print(len(c))
for w, n in sorted(c.items()):
    print(n, w)
