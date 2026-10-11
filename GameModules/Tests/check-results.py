#!/usr/bin/env python3
"""Compares the Mac harness logs written by run-tests.sh with expected.tsv.

Usage: python3 check-results.py <work folder>/src expected.tsv [pattern]
Prints one line per page version and a summary; exits 1 if anything is not as expected.
Every version folder must have a row in expected.tsv, and every row whose name contains the pattern
(run-tests.sh's `mac <text>`; empty = every row) must have a version folder, so a stray file (an
iCloud "name 2.swift" copy) or a deleted variant fails the run.

The hint column is what the engine's first failing check returned. The student never sees it (the
header above the game shows only ✅ / ❌, a short status and "Can't find:" lines); it tells the
mistakes apart. Since v6 there is no hint check: nothing a check returns is shown. (The prose check,
for the pages' words, is check-prose.py: run-tests.sh runs it in every mode.)
"""
import os
import sys

src, expected_path = sys.argv[1], sys.argv[2]
pattern = sys.argv[3] if len(sys.argv) > 3 else ""
expected = {}
for line in open(expected_path, encoding="utf-8"):
    if not line.strip() or line.startswith("#"):
        continue
    cols = line.rstrip("\n").split("\t")
    name, checks, hint, bot, fuzz, note = cols[:6]
    warn = cols[6] if len(cols) > 6 else "-"
    expected[name] = dict(checks=checks, hint=hint, bot=bot, fuzz=fuzz, note=note, warn=warn)


def results(log):
    r = {}
    for line in log.split("\n"):
        if line.startswith("  RESULT "):
            key, _, value = line[len("  RESULT "):].partition("=")
            r[key] = value
    return r


rows, problems = [], []
fuzz_runs = fuzz_complete = 0
gate_runs = gate_reached = 0
counts = {"starter": [0, 0], "solution": [0, 0], "other": [0, 0]}
for slug in sorted(os.listdir(src)):
    if not os.path.isdir(os.path.join(src, slug)):
        continue
    for version in sorted(os.listdir(os.path.join(src, slug))):
        name = slug + "/" + version
        if os.path.isdir(os.path.join(src, name)) and name not in expected:
            problems.append(name)
            rows.append(f"FAIL {name:<36} has no row in expected.tsv (a stray or misnamed variant file?)")
for name, exp in expected.items():
    d = os.path.join(src, name)
    log_path = os.path.join(d, "log.txt")
    if not os.path.isdir(d):
        if pattern in name:
            problems.append(name)
            rows.append(f"FAIL {name:<36} is in expected.tsv, but there is no such page version (deleted variant?)")
        continue                                  # filtered out by a pattern
    kind = name.split("/")[1] if name.split("/")[1] in ("starter", "solution") else "other"
    counts[kind][1] += 1
    log = open(log_path, encoding="utf-8").read() if os.path.exists(log_path) else ""
    r = results(log)
    bad = []
    if "checks" not in r:
        err = os.path.join(d, "err.txt")
        first = [l for l in open(err, encoding="utf-8")] if os.path.exists(err) else []
        first = [l.strip() for l in first if "error:" in l][:2]
        bad.append("did not run: " + ("; ".join(first) or "no log"))
    else:
        if r["checks"] != exp["checks"]:
            bad.append(f"checks {r['checks']} (expected {exp['checks']})")
        if exp["hint"] != "-" and exp["hint"] not in r.get("hint", ""):
            bad.append(f"hint \"{r.get('hint', '')}\" (expected it to contain \"{exp['hint']}\")")
        if exp["hint"] == "-" and r.get("hint"):
            bad.append(f"unexpected hint \"{r['hint']}\"")
        if exp["warn"] != "-" and exp["warn"] not in r.get("warn", ""):
            bad.append(f"panel warning \"{r.get('warn', '')}\" (expected it to contain \"{exp['warn']}\")")
        if exp["warn"] == "-" and r.get("warn"):
            bad.append(f"unexpected panel warning \"{r['warn']}\"")
        done, seeds = (int(n) for n in r.get("bot", "0/0").split()[0].split("/"))
        if exp["bot"] == "complete" and done == 0:
            bad.append(f"the bot never completed the page (0/{seeds} seeds)")
        if exp["bot"] == "none" and done > 0:
            bad.append(f"the page was completed ({done}/{seeds} seeds) but a check should block it")
        # Busy Bees: Mark's bee-spacing targets (Headless BEEWINDOW) on the solution.
        if name == "10-bee/solution" and "beewindow" not in r:
            bad.append("no BEEWINDOW measurement")
        if "beewindow" in r and r["beewindow"] != "ok":
            bad.append("bee spacing: " + r["beewindow"])
        if exp["fuzz"] != "-":
            if "fuzz" not in r:
                bad.append("no random-input runs")
            else:
                reached, completed, runs = (int(n) for n in r["fuzz"].split("/"))
                fuzz_runs += runs
                fuzz_complete += completed
                if completed:
                    bad.append(f"random input completed the page {completed}/{runs} times")
                if exp["fuzz"] == "gate":
                    gate_runs += runs
                    gate_reached += reached
                    if reached:
                        bad.append(f"random input reached an unlocked 🚩 {reached}/{runs} times")
    bot = r.get("bot", "?").split()[0]
    fz = r.get("fuzz", "")
    detail = f"checks {r.get('checks', '?'):<4} bot {bot:<6}" + (f" random 🚩 {fz.split('/')[0]}/{fz.split('/')[2]}" if fz else "")
    if bad:
        problems.append(name)
        rows.append(f"FAIL {name:<36} {detail}\n       " + "\n       ".join(bad))
    else:
        counts[kind][0] += 1
        hint = f"  hint: {r['hint'][:70]}" if r.get("hint") else ""
        rows.append(f"ok   {name:<36} {detail}{hint}")

print("\n".join(rows))
print()
print(f"starters  as expected: {counts['starter'][0]}/{counts['starter'][1]} (pages with checks fail them, with the expected failing check)")
print(f"solutions as expected: {counts['solution'][0]}/{counts['solution'][1]} (pass every check; the bot completes the page)")
print(f"other versions as expected: {counts['other'][0]}/{counts['other'][1]} (mistakes fail the expected check, other right answers pass)")
print(f"random input: {fuzz_runs} runs on starters and wrong-* versions, page completed {fuzz_complete} times; "
      f"gated starters reached an unlocked 🚩 {gate_reached} times in {gate_runs} runs")
if problems:
    print(f"NOT AS EXPECTED: {len(problems)}: " + ", ".join(problems))
    sys.exit(1)
print("ALL AS EXPECTED")
