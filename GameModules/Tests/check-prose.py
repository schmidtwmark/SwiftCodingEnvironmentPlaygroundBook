#!/usr/bin/env python3
"""The prose check: the book's words never give an answer away, and stay short.

Usage: python3 GameModules/Tests/check-prose.py [Chapters folder]   (default: the repo's)
run-tests.sh runs it in every mode, right after `chain.py check`. It needs no engine build.
Prints one line per page and a summary; exits 1 if anything is wrong.

A page's answer is the code lines its finished code adds to its starter (whitespace ignored; lines
under 8 characters, comments and "} else {" don't count), plus the pieces of those lines that would
give most of a line away: what's inside a pair of parentheses, the right side of an =, and an if's
condition, 12 characters or more, with an operator or a comma, that the starter doesn't already show.
The starter and the finished code are read from the page file the way inject_solutions.sh ships them.

  - Code pages (the 23 of chain.py's PAGES): the prose card shows no answer line or piece of this
    page or of any later page. It has a "## Your turn" with 1-3 bullets and one "**Your tools:**"
    line (not Design Your Own Game), a "**Controls:**" line only on page 1, at most WORD_LIMIT words
    (words have a letter or a digit), and ends with chain.py's Stuck line (not the last page).
  - Hints pages (one per Part with code, chain.py's PARTS): prose only (no code, no hidden code, no
    poster), Name "Hints: <Part>", HiddenByDefault, listed last in its chapter after the Part's code
    pages; one "Finished this Part? Go to the next page: **<title>**." line that names the next
    Part's first code page; a "## <title>" section for each code page of the Part, in order, each
    with **Hint 1:**, **Hint 2:** and **Hint 3:**; and no answer line or piece of any page of its
    Part or a later Part.
  - The README page: no page's answer line with = or {, and no piece of any page's answer.
"""
import importlib.util
import os
import plistlib
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(os.path.dirname(HERE))
spec = importlib.util.spec_from_file_location("chain", os.path.join(REPO, "GameModules", "Tools", "chain.py"))
chain = importlib.util.module_from_spec(spec)
spec.loader.exec_module(chain)

CHAPTERS = sys.argv[1] if len(sys.argv) > 1 else os.path.join(REPO, "PlaygroundBook", "Chapters")
WORD_LIMIT = {"01-walk": 140, "23-design": 300}   # every other code page: DEFAULT_WORD_LIMIT
DEFAULT_WORD_LIMIT = 100


def page_dir(chapter, folder):
    return os.path.join(CHAPTERS, chapter + ".playgroundchapter", "Pages", folder + ".playgroundpage")


def read(path):
    return open(path, encoding="utf-8").read()


def card_lines(text):
    """The lines of the page's prose: the first /*: ... */ after the hidden code (a code page), or
    every /*: ... */ of a prose-only page."""
    lines, out, inside = text.split("\n"), [], False
    start = lines.index("//#-end-hidden-code") + 1 if "//#-end-hidden-code" in lines else 0
    for line in lines[start:]:
        if not inside and line.startswith("/*:"):
            inside = True
        elif inside and line.strip() == "*/":
            inside = False
            if start:
                break
        elif inside:
            out.append(line)
    return out


def starter_code(text):
    """The visible code under the prose card (what the student page shows)."""
    lines = text.split("\n")
    e = lines.index("//#-end-hidden-code")
    c = lines.index(" */", e)
    return lines[c + 1:]


def solution_code(text):
    """The finished code: the commented block after "MARK: - Solution" (as inject_solutions.sh)."""
    out, found = [], False
    for line in text.split("\n"):
        if "MARK: - Solution" in line:
            found = True
        elif "//#-end-hidden-code" in line:
            found = False
        elif found and re.match(r"^// *$", line):
            out.append("")
        elif found and line.startswith("// "):
            out.append(line[3:])
    return out


def code_line(line):
    line = line.split("//")[0] if '"' not in line.split("//")[0] or line.count('"') % 2 == 0 else line
    return " ".join(line.split())


def answer_lines(text):
    start = {code_line(l) for l in starter_code(text)}
    return {l for l in (code_line(l) for l in solution_code(text)) if len(l) >= 8 and l not in start}


def answer_pieces(text):
    starter = " ".join(" ".join(starter_code(text)).split())
    out = set()
    for line in answer_lines(text):
        for m in re.finditer(r'\(([^()]*(\([^()]*\))?[^()]*)\)', line):
            out.add(m.group(0))
            out.add(m.group(1))
            if m.group(2):                       # one pair inside: String(game.timer / 60)
                out.add(m.group(2))
                out.add(m.group(2)[1:-1])
        left, eq, right = line.partition("=")
        if eq and not right.startswith("=") and not left.endswith(("!", "<", ">")):
            out.add(right)
        m = re.match(r'(?:\} )?(?:else )?if (.*) \{$', line)
        if m:
            out.add(m.group(1))
    # Only pieces with an operator or a comma: a lone tool call (`isPressed(.left)`) is a tool's
    # name, which the prose may give.
    return {x.strip() for x in out if len(x.strip()) >= 12 and x.strip() not in starter
            and re.search(r' [-+*/<>]=? | [=!]= |,', x)}


def flat(lines):
    return " ".join(" ".join(lines).replace("`", "").split())


def words(lines):
    return len([t for t in " ".join(lines).split() if re.search(r"[A-Za-z0-9]", t)])


rows, problems = [], []


def fail(name, why):
    problems.append(name)
    rows.append(f"FAIL {name:<28} {why}")


# ---- code pages, last to first, collecting the answers of this page and every later one
pages = []
for slug, case, chapter, folder, title in chain.PAGES:
    path = os.path.join(page_dir(chapter, folder), "main.swift")
    pages.append((slug, chapter, title, path, read(path) if os.path.exists(path) else None))
later = set()                      # answer lines and pieces of this page and every later page
later_from = {}                    # slug -> that set, for the Hints pages
every_answer = set()               # for the README: answer lines with = or {, and pieces
for slug, chapter, title, path, text in reversed(pages):
    if text is None:
        fail(slug, "no page at " + path)
        continue
    mine = {a for a in answer_lines(text) if a != "} else {"}
    pieces = answer_pieces(text)
    later |= mine | pieces
    later_from[slug] = set(later)
    every_answer |= {a for a in mine if "=" in a or "{" in a} | pieces
    card = card_lines(text)
    leaked = sorted(a for a in later if a in flat(card))
    n = words(card)
    limit = WORD_LIMIT.get(slug, DEFAULT_WORD_LIMIT)
    bad = []
    if leaked:
        bad.append("shows an answer line or piece: " + " / ".join(leaked)[:200])
    stuck = chain.stuck_line(slug)
    if stuck and not (card and card[-1].strip() == stuck):
        bad.append(f"doesn't end with \"{stuck}\"")
    if n > limit:
        bad.append(f"{n} words (at most {limit}: move the rest to its Hints page)")
    stripped = [l.strip() for l in card]
    if "## Your turn" not in stripped:
        bad.append("has no \"## Your turn\"")
    else:
        after = stripped[stripped.index("## Your turn") + 1:]
        bullets = 0
        for l in after:
            if l.startswith("- "):
                bullets += 1
            elif l and bullets:
                break
        if not 1 <= bullets <= 3:
            bad.append(f"\"Your turn\" has {bullets} bullets (1 to 3)")
    tools = [l for l in stripped if l.startswith("**Your tools:**")]
    if slug != chain.PAGES[-1][0] and len(tools) != 1:
        bad.append(f"has {len(tools)} \"**Your tools:**\" lines (one)")
    if slug != "01-walk" and any(l.startswith("**Controls:**") for l in stripped):
        bad.append("has a Controls line (only page 1 and README have one)")
    for b in bad:
        fail(slug, b)
    if not bad:
        rows.append(f"ok   {slug:<28} {n:>3} words")
rows.reverse()

# ---- Hints pages
for chapter, (part, hints) in chain.PARTS.items():
    mine = [p for p in chain.PAGES if p[2] == chapter]
    manifest_path = os.path.join(CHAPTERS, chapter + ".playgroundchapter", "Manifest.plist")
    listed = plistlib.load(open(manifest_path, "rb")).get("Pages", []) if os.path.exists(manifest_path) else None
    want = [p[3] + ".playgroundpage" for p in mine] + [(hints or "README") + ".playgroundpage"]
    if listed is None:
        fail(chapter, "no chapter Manifest.plist")
    elif listed != want:
        fail(chapter, f"its Manifest.plist lists {listed}, expected {want}")
    if not hints:
        continue
    name = chain.hints_title(chapter)
    d = page_dir(chapter, hints)
    if not os.path.isdir(d):
        fail(name, "no page at " + d)
        continue
    bad = []
    files = sorted(f for f in os.listdir(d) if f != ".DS_Store")
    if files != ["Manifest.plist", "main.swift"]:
        bad.append(f"has files {files} (only Manifest.plist and main.swift)")
    m = plistlib.load(open(os.path.join(d, "Manifest.plist"), "rb")) if "Manifest.plist" in files else {}
    if m.get("Name") != name:
        bad.append(f"manifest Name is {m.get('Name')!r}, expected {name!r}")
    if m.get("LiveViewMode") != "HiddenByDefault" or "PosterReference" in m:
        bad.append("manifest: needs LiveViewMode HiddenByDefault and no PosterReference (a prose-only page, like README)")
    text = read(os.path.join(d, "main.swift")) if "main.swift" in files else ""
    if "//#-hidden-code" in text or "MARK: - Solution" in text:
        bad.append("has hidden code or a solution (a Hints page is prose only)")
    outside = re.sub(r"/\*:.*?\n \*/", "", text, flags=re.S).strip()
    if outside:
        bad.append("has code outside its prose: " + outside.split("\n")[0][:60])
    card = card_lines(text)
    stripped = [l.strip() for l in card]
    if not stripped or stripped[0] != "# " + name:
        bad.append(f"its prose doesn't start with \"# {name}\"")
    after_part = chain.PAGES[chain.PAGES.index(mine[-1]) + 1:]
    if after_part:
        finished = "Finished this Part? Go to the next page: **" + after_part[0][4] + "**."
        found = [l for l in stripped if l.startswith("Finished this Part?")]
        if found != [finished]:
            bad.append(f"needs one line \"{finished}\" (the next Part's first page), found {found}")
    heads = [i for i, l in enumerate(stripped) if l.startswith("## ")]
    if [stripped[i][3:] for i in heads] != [p[4] for p in mine]:
        bad.append(f"its sections are {[stripped[i][3:] for i in heads]}, expected one per page: {[p[4] for p in mine]}")
    else:
        for k, i in enumerate(heads):
            section = stripped[i:heads[k + 1] if k + 1 < len(heads) else len(stripped)]
            at = [next((j for j, l in enumerate(section) if l.startswith(f"**Hint {h}:**")), -1) for h in (1, 2, 3)]
            if -1 in at or at != sorted(at):
                bad.append(f"\"{mine[k][4]}\" needs **Hint 1:**, **Hint 2:** and **Hint 3:**, in order")
    leaked = sorted(a for a in later_from.get(mine[0][0], set()) if a in flat(card))
    if leaked:
        bad.append("shows an answer line or piece: " + " / ".join(leaked)[:200])
    for b in bad:
        fail(name, b)
    if not bad:
        rows.append(f"ok   {name:<28} {words(card):>4} words, {len(mine)} pages x 3 hints")

# ---- the README page: a reference with generic examples, never a page's answer
readme = os.path.join(page_dir("Chapter16", "README"), "main.swift")
if os.path.exists(readme):
    leaked = sorted(a for a in every_answer if a in flat([read(readme)]))
    if leaked:
        fail("README", "shows a page's answer: " + " / ".join(leaked)[:200])
    else:
        rows.append(f"ok   {'README':<28} no page's answer")
else:
    fail("README", "no page at " + readme)

print("\n".join(rows))
nhints = sum(1 for _, h in chain.PARTS.values() if h)
print(f"prose check: {len(problems)} problems in {len(chain.PAGES)} pages, {nhints} Hints pages and the README "
      "(no answer line or piece of one; short cards that end with the Stuck line; 3 hints per page)")
sys.exit(1 if problems else 0)
