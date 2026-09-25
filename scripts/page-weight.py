#!/usr/bin/env python3
"""Write each built page's measured weight into its footer.

Hugo renders the footer's eco-design line with a `~?` placeholder: a page can't
know its own final byte size while it is still being rendered. This replaces
that placeholder with the real figure — the page's own HTML bytes plus the bytes
of the stylesheet it links. There is no JS, no webfont and no image on this
site, so those two numbers are the whole page.

Run after `hugo --minify`, from scripts/build.sh. Idempotent: the placeholder
pattern also matches an already-written number, so re-running over an existing
public/ recomputes in place.
"""

import os
import re
import sys

PUBLIC = "public"

# `hugo --minify` strips HTML comments and collapses whitespace runs, so the
# markers have to be markup. The patterns tolerate single, double or missing
# attribute quotes, so they survive any minifier quoting setting.
FOOTER_LINE = re.compile(
    r"""<p[^>]*class=["']?[^"'>]*\bpage-weight\b[^>]*>(.*?)</p>""", re.S)
FIGURE = re.compile(r"~(?:\?|[0-9]+(?:[.,][0-9]+)?)")
HTML_LANG = re.compile(r"""<html[^>]*\blang=["']?([A-Za-z-]+)""")
STYLESHEET = re.compile(
    r"""<link[^>]*\brel=["']?stylesheet["']?[^>]*\bhref=["']?([^"'>\s]+)""")


def stylesheet_bytes(page, html):
    """Size of the stylesheet this page links.

    Read from the page's own <link> rather than globbed: the filename is
    fingerprinted, and Hugo does not clear public/, so a glob can pick up a
    stale bundle from an earlier build.
    """
    match = STYLESHEET.search(html)
    if not match:
        sys.exit(f"{page}: no <link rel=stylesheet> to measure")
    path = os.path.join(PUBLIC, match.group(1).split("?")[0].lstrip("/"))
    if not os.path.isfile(path):
        sys.exit(f"{page}: linked stylesheet not found at {path}")
    return os.path.getsize(path)


def figure(total_bytes, lang):
    """The `~9,4` token: French writes the decimal comma, everything else a point."""
    text = f"{total_bytes / 1024:.1f}"
    return "~" + (text.replace(".", ",") if lang.startswith("fr") else text)


def rewrite(page):
    """Return True if the page carried a figure and was rewritten."""
    with open(page, "rb") as handle:
        raw = handle.read()
    html = raw.decode("utf-8")

    line = FOOTER_LINE.search(html)
    if not line:
        return False  # no footer, e.g. the /fr/ redirect stub

    token = FIGURE.search(html, line.start(1), line.end(1))
    if not token:
        sys.exit(f"{page}: .page-weight has no ~figure to replace")

    lang_match = HTML_LANG.search(html)
    lang = lang_match.group(1) if lang_match else ""

    # Tokens are ASCII, so character counts are byte counts here. The figure
    # counts itself: assume a 5-byte token (`~20,9`); 1-10 KB and 100+ KB pages
    # end up a byte off, invisible at 0.1 KB precision.
    base = len(raw) - len(token.group(0)) + stylesheet_bytes(page, html)
    replacement = figure(base + 5, lang)

    with open(page, "wb") as handle:
        handle.write(
            (html[:token.start()] + replacement + html[token.end():]).encode("utf-8"))
    return True


def main():
    if not os.path.isdir(PUBLIC):
        sys.exit(f"{PUBLIC}/ not found — run hugo first")

    written = sum(
        rewrite(os.path.join(root, name))
        for root, _dirs, names in os.walk(PUBLIC)
        for name in sorted(names)
        if name.endswith(".html"))

    if not written:
        sys.exit("no .page-weight figure found in any page — "
                 "did layouts/partials/footer.html change?")

    print(f"page weight written to {written} page(s)")


if __name__ == "__main__":
    main()
