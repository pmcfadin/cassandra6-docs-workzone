#!/usr/bin/env bash
#
# xref-report.sh - Parse Antora structured (JSON) build logs and summarize
# error-level (or other) log messages for broken-xref remediation work.
#
# Input: Antora JSON log on stdin or as a positional argument. Each line is a
# JSON object with keys: level, name, msg, file.path, source.refname,
# source.url, time (epoch ms).
#
# Default: prints a deterministic human-readable report.
# Flags:
#   --baseline <path>       Diff against a baseline JSON (fixed/introduced/net)
#   --emit-baseline         Write baseline JSON to stdout
#   --branch <refname>      Filter to a single source.refname
#   --level <lvl>           Filter by log level (default: error)
#   --source-build <str>    Baseline metadata: e.g. cassandra-website/2752
#   --source-url <url>      Baseline metadata: Jenkins console URL
#   --capture-date <YYYY-MM-DD>  Baseline metadata (default: today)
#   --trunk-sha <sha>       Baseline metadata: upstream SHA at capture time
#   -h, --help              Show this help
#
# Always exits 0. This is a reporting tool, not a gate.

set -euo pipefail

usage() {
  sed -n '2,24p' "$0" | sed 's/^# \{0,1\}//'
}

LEVEL="error"
BRANCH=""
BASELINE=""
EMIT_BASELINE=0
SOURCE_BUILD=""
SOURCE_URL=""
CAPTURE_DATE="$(date +%Y-%m-%d)"
TRUNK_SHA=""
INPUT_FILE=""

while [ $# -gt 0 ]; do
  case "$1" in
    --baseline)       BASELINE="${2-}"; shift 2 ;;
    --emit-baseline)  EMIT_BASELINE=1; shift ;;
    --branch)         BRANCH="${2-}"; shift 2 ;;
    --level)          LEVEL="${2-}"; shift 2 ;;
    --source-build)   SOURCE_BUILD="${2-}"; shift 2 ;;
    --source-url)     SOURCE_URL="${2-}"; shift 2 ;;
    --capture-date)   CAPTURE_DATE="${2-}"; shift 2 ;;
    --trunk-sha)      TRUNK_SHA="${2-}"; shift 2 ;;
    -h|--help)        usage; exit 0 ;;
    --)               shift; break ;;
    -*)               echo "unknown flag: $1" >&2; usage; exit 0 ;;
    *)                INPUT_FILE="$1"; shift ;;
  esac
done

if ! command -v python3 >/dev/null 2>&1; then
  echo "xref-report.sh requires python3 (json stdlib). jq alone is insufficient for baseline diffing." >&2
  exit 0
fi

if [ -n "$INPUT_FILE" ] && [ ! -r "$INPUT_FILE" ]; then
  echo "cannot read: $INPUT_FILE" >&2
  exit 0
fi

# The Python body has to read stdin (the Antora log), so we cannot pass it
# via a heredoc on the same invocation (heredoc consumes stdin). Write to a
# temp file and exec instead.
PY_SCRIPT="$(mktemp -t xref-report.XXXXXX)"
trap 'rm -f "$PY_SCRIPT"' EXIT
cat > "$PY_SCRIPT" <<'PY'
import json, sys
from collections import Counter

level_filter   = sys.argv[1]
branch_filter  = sys.argv[2]
baseline_path  = sys.argv[3]
emit_baseline  = sys.argv[4] == "1"
source_build   = sys.argv[5]
source_url     = sys.argv[6]
capture_date   = sys.argv[7]
trunk_sha      = sys.argv[8]
input_file     = sys.argv[9]

CATEGORIES = [
    ("xref",    "target of xref"),
    ("image",   "target of image"),
    ("include", "target of include"),
    ("table",   "dropping cells"),
]
SECTION_MARKERS = ("section title", "level 0 sections")

def classify(msg):
    for name, marker in CATEGORIES:
        if marker in msg:
            return name
    for marker in SECTION_MARKERS:
        if marker in msg:
            return "section"
    return "other"

if input_file:
    stream = open(input_file, "r", encoding="utf-8", errors="replace")
else:
    stream = sys.stdin

by_type    = Counter()
by_branch  = Counter()
by_msg     = Counter()
by_key     = Counter()   # (branch, category, msg) -> count
total      = 0

for line in stream:
    line = line.strip()
    if not line or line[0] != "{":
        continue
    try:
        rec = json.loads(line)
    except ValueError:
        continue
    if rec.get("level") != level_filter:
        continue
    refname = ((rec.get("source") or {}).get("refname")) or ""
    if branch_filter and refname != branch_filter:
        continue
    msg = rec.get("msg") or ""
    cat = classify(msg)
    total                         += 1
    by_type[cat]                  += 1
    by_branch[refname]            += 1
    by_msg[msg]                   += 1
    by_key[(refname, cat, msg)]   += 1

def sorted_counter_by_count_then_key(counter):
    # Deterministic: count desc, then key asc.
    return sorted(counter.items(), key=lambda kv: (-kv[1], kv[0]))

top_targets_all = [
    {"msg": m, "count": c}
    for m, c in sorted_counter_by_count_then_key(by_msg)
]

# target_counts: full (branch, category, msg) -> count records. Primary
# delta source; enables branch- and category-scoped diffs without losing
# dimensional information.
target_counts_all = [
    {"branch": b, "category": c, "msg": m, "count": n}
    for (b, c, m), n in sorted(
        by_key.items(),
        key=lambda kv: (-kv[1], kv[0][0], kv[0][1], kv[0][2]),
    )
]

if emit_baseline:
    doc = {
        "by_branch":             dict(sorted(by_branch.items())),
        "by_type":               dict(sorted(by_type.items())),
        "capture_date":          capture_date,
        "level":                 level_filter,
        "schema_version":        2,
        "source_build":          source_build,
        "source_url":            source_url,
        "target_counts":         target_counts_all,
        "top_targets":           top_targets_all,
        "total":                 total,
        "trunk_sha_at_capture":  trunk_sha,
    }
    if branch_filter:
        doc["branch_filter"] = branch_filter
    json.dump(doc, sys.stdout, indent=2, sort_keys=True)
    sys.stdout.write("\n")
    sys.exit(0)

def print_report():
    print(f"Total {level_filter}-level entries: {total}")
    if branch_filter:
        print(f"Filter: branch={branch_filter}")
    print()
    print("By category:")
    cat_order = ["xref", "image", "include", "section", "table", "other"]
    width = max((len(c) for c in cat_order), default=8)
    for cat in cat_order:
        n = by_type.get(cat, 0)
        if n or cat in ("xref","image","include","section","table"):
            print(f"  {cat:<{width}}  {n:>6}")
    print()
    print("By branch:")
    if by_branch:
        bwidth = max(len(b) for b in by_branch)
        for refname, n in sorted(by_branch.items(), key=lambda kv: (-kv[1], kv[0])):
            label = refname or "(no refname)"
            print(f"  {label:<{bwidth}}  {n:>6}")
    else:
        print("  (none)")
    print()
    print("Top 20 most-frequent messages:")
    for item in top_targets_all[:20]:
        print(f"  {item['count']:>4}  {item['msg']}")

if baseline_path:
    try:
        with open(baseline_path, "r", encoding="utf-8") as fh:
            base = json.load(fh)
    except (OSError, ValueError) as exc:
        print(f"baseline read failed: {exc}", file=sys.stderr)
        sys.exit(0)

    base_target_counts = base.get("target_counts")
    if base_target_counts is None:
        # Legacy baseline (schema_version < 2) only has msg-keyed counts.
        # Branch-scoped diff is not representable; refuse rather than
        # silently producing misleading numbers.
        if branch_filter:
            print(
                "baseline lacks target_counts (branch/category dimensions); "
                "re-emit the baseline with this script, or drop --branch.",
                file=sys.stderr,
            )
            print_report()
            sys.exit(0)
        base_key_counts = {
            ("", "", item["msg"]): int(item["count"])
            for item in base.get("top_targets", [])
        }
        cur_key_counts = {
            ("", "", m): n for m, n in by_msg.items()
        }
        legacy_msg_only = True
    else:
        base_key_counts = {
            (item["branch"], item["category"], item["msg"]): int(item["count"])
            for item in base_target_counts
        }
        if branch_filter:
            base_key_counts = {
                k: v for k, v in base_key_counts.items()
                if k[0] == branch_filter
            }
        cur_key_counts = dict(by_key)
        legacy_msg_only = False

    fixed = 0
    introduced = 0
    fixed_by_branch = Counter()
    fixed_by_cat    = Counter()
    introduced_by_branch = Counter()
    introduced_by_cat    = Counter()
    fixed_rows = []
    introduced_rows = []

    all_keys = set(base_key_counts.keys()) | set(cur_key_counts.keys())
    for key in all_keys:
        bc = base_key_counts.get(key, 0)
        cc = cur_key_counts.get(key, 0)
        if cc < bc:
            d = bc - cc
            fixed += d
            fixed_by_branch[key[0]] += d
            fixed_by_cat[key[1]]    += d
            fixed_rows.append((d, key))
        elif cc > bc:
            d = cc - bc
            introduced += d
            introduced_by_branch[key[0]] += d
            introduced_by_cat[key[1]]    += d
            introduced_rows.append((d, key))
    net = introduced - fixed

    print_report()
    print()
    print("Delta vs baseline:")
    print(f"  baseline total: {base.get('total', 'n/a')}  ({base.get('source_build','')})")
    if branch_filter and not legacy_msg_only:
        scoped = sum(base_key_counts.values())
        print(f"  baseline scope: branch={branch_filter} ({scoped})")
    print(f"  current  total: {total}")
    print(f"  fixed:          {fixed}")
    print(f"  introduced:     {introduced}")
    print(f"  net:            {net:+d}")
    if legacy_msg_only:
        print()
        print("  WARNING: baseline is legacy schema (msg-only); per-branch "
              "and per-category delta not available.")

    def key_label(k):
        if legacy_msg_only:
            return k[2]
        return f"[{k[0]}/{k[1]}] {k[2]}"

    if fixed_by_branch and not legacy_msg_only:
        print()
        print("  Fixed by branch:")
        for b, n in sorted(fixed_by_branch.items(), key=lambda kv: (-kv[1], kv[0])):
            print(f"    -{n:<4} {b or '(no refname)'}")
    if introduced_by_branch and not legacy_msg_only:
        print()
        print("  Introduced by branch:")
        for b, n in sorted(introduced_by_branch.items(), key=lambda kv: (-kv[1], kv[0])):
            print(f"    +{n:<4} {b or '(no refname)'}")
    if fixed_rows:
        print()
        print("  Fixed (top 10):")
        for d, key in sorted(fixed_rows, key=lambda x: (-x[0], x[1]))[:10]:
            print(f"    -{d:<4} {key_label(key)}")
    if introduced_rows:
        print()
        print("  Introduced (top 10):")
        for d, key in sorted(introduced_rows, key=lambda x: (-x[0], x[1]))[:10]:
            print(f"    +{d:<4} {key_label(key)}")
else:
    print_report()
PY

python3 "$PY_SCRIPT" "$LEVEL" "$BRANCH" "$BASELINE" "$EMIT_BASELINE" \
  "$SOURCE_BUILD" "$SOURCE_URL" "$CAPTURE_DATE" "$TRUNK_SHA" \
  "$INPUT_FILE"
