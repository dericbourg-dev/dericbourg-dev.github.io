#!/usr/bin/env sh
set -eu

# Regression harness for the footer page-weight line (layouts/partials/footer.html).
#
# Guards against the bug class where the line reports a figure that does not
# depend on the page printing it: it used to measure only the shared CSS bundle,
# so every page claimed "CSS ~6 Ko" while real sizes span roughly 4-20 KB.
#
# Reads public/, never creates it. Run after a build:
#     sh scripts/build.sh && sh scripts/test-page-weight.sh

[ -f config/_default/hugo.toml ] || {
  echo "test-page-weight: run from the repository root" >&2
  exit 1
}
[ -d public ] || {
  echo "test-page-weight: public/ not found — run 'sh scripts/build.sh' first" >&2
  exit 1
}

PUBLIC_DIR=public python3 - <<'PY'
import glob
import html
import os
import re
import sys

# Tolerance: 50 bytes is half of the last printed digit at one-decimal
# precision, so anything larger means the printed digit itself is wrong.
# The post-build rewrite is single-pass and shifts the file by 1-2 bytes
# after measuring it; 50 B absorbs that with ~25x headroom.
EXACT_TOLERANCE_B = 50

# content/ holds 8 markdown files (_index, contact, cv, references x fr/en)
# plus a 404 per language: 10 pages carry a footer. A floor, not an
# equality — adding a page must not fail, but a glob matching nothing must.
MIN_PAGES = 10

PUBLIC = os.environ["PUBLIC_DIR"]

# Hugo's minifier drops attribute quotes when they aren't syntactically
# required (observed: `class="page-weight"` becomes `class=page-weight`), so
# this must tolerate single, double, or missing quotes.
LINE_RE = re.compile(r'<p[^>]*class=["\']?[^"\'>]*\bpage-weight\b[^>]*>(.*?)</p>', re.S)
# FR prints a decimal comma ("15,7 Ko"), EN a point ("15.7 KB").
FIGURE_RE = re.compile(r'([0-9]+(?:[.,][0-9]+)?)\s*(?:Ko|KB)\b')
# Same shape as the two above: tolerant of single, double or missing quotes.
STYLESHEET_RE = re.compile(r'<link[^>]*\brel=["\']?stylesheet["\']?[^>]*\bhref=["\']?([^"\'>\s]+)')


def die(msg):
    sys.stderr.write("test-page-weight: %s\n" % msg)
    raise SystemExit(1)


def css_bytes(root, rel, raw):
    """Size of the stylesheet this page links.

    Read from the page's own <link> rather than globbed: the name is
    fingerprinted and Hugo does not clear public/, so a glob can match a stale
    bundle from an earlier build — or match two and fail on a build that is
    perfectly fine. Same rule as page-weight.py, re-derived here rather than
    imported: the test has to measure the page independently of the code it is
    checking.
    """
    match = STYLESHEET_RE.search(raw)
    if match is None:
        die("%s: no <link rel=stylesheet> to measure" % rel)
    path = os.path.join(root, match.group(1).split("?")[0].lstrip("/"))
    if not os.path.isfile(path):
        die("%s: linked stylesheet not found at %s" % (rel, path))
    return os.path.getsize(path)


def scan(root):
    """Map rel path -> (printed bytes, real html+css bytes), plus skipped stubs."""
    pages, stubs = {}, []
    for path in sorted(glob.glob(os.path.join(root, "**", "*.html"), recursive=True)):
        rel = os.path.relpath(path, root)
        with open(path, encoding="utf-8") as fh:
            raw = fh.read()
        line = LINE_RE.search(raw)
        if line is None:
            # Only a redirect stub may lack the line (public/fr/index.html).
            # Matched by shape, not by path, so a real page losing its footer fails.
            if re.search(r'http-equiv=["\']?refresh\b', raw, re.I) and os.path.getsize(path) < 1024:
                stubs.append(rel)
                continue
            die('%s: no <p class="page-weight"> line — the footer stopped rendering it' % rel)
        figure = FIGURE_RE.search(html.unescape(line.group(1)))
        if figure is None:
            die("%s: .page-weight line carries no parseable figure: %r"
                % (rel, line.group(1)))
        printed = float(figure.group(1).replace(",", ".")) * 1024
        pages[rel] = (printed, os.path.getsize(path) + css_bytes(root, rel, raw))
    return pages, stubs


built, stubs = scan(PUBLIC)

results = []


def check(name, ok, detail):
    results.append((ok, name, detail))


# Given a full build of the site
# When every .html file under public/ is inspected
# Then each one prints a figure, or is a redirect stub, and enough were found
check(
    "pageWeight_ofBuiltSite_coversEveryRenderedPage",
    len(built) >= MIN_PAGES,
    "checked %d pages (floor %d), skipped %d redirect stub(s): %s"
    % (len(built), MIN_PAGES, len(stubs), stubs),
)

# Given the figures printed across all pages
# When they are compared to each other
# Then they are not all the same — the original bug, stated directly
printed = sorted(p for p, _ in built.values())
distinct = len({round(p) for p in printed})
spread = printed[-1] - printed[0] if printed else 0
check(
    "pageWeight_ofBuiltSite_variesAcrossPages",
    distinct > 1 and spread >= 2048,
    "%d distinct figure(s) across %d pages, spread %.1f KB (need >1 distinct and >=2.0 KB)"
    % (distinct, len(built), spread / 1024),
)

# Given the post-build rewrite has run over public/
# When each printed figure is compared to os.stat(page) + os.stat(css)
# Then it is accurate to within half of its last printed digit
off = {rel: p - real for rel, (p, real) in built.items()
       if abs(p - real) > EXACT_TOLERANCE_B}
check(
    "pageWeight_ofEachBuiltPage_matchesHtmlPlusCssBytes",
    not off,
    "; ".join("%s off by %+.0f B" % (r, d) for r, d in sorted(off.items()))
    or "all %d pages within +/-%d B" % (len(built), EXACT_TOLERANCE_B),
)

print("%-32s %9s %9s %8s" % ("page", "printed", "html+css", "delta"))
for rel in sorted(built):
    p, real = built[rel]
    print("%-32s %6.1f KB %6.1f KB %8.0f" % (rel, p / 1024, real / 1024, p - real))
print()

failed = 0
for ok, name, detail in results:
    print("%s %s\n       %s" % ("PASS" if ok else "FAIL", name, detail))
    failed += 0 if ok else 1

if failed:
    sys.stderr.write("\ntest-page-weight: %d of %d checks failed\n"
                     % (failed, len(results)))
    raise SystemExit(1)
print("\ntest-page-weight: %d checks passed" % len(results))
PY
