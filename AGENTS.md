# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Personal professional website for Alban Dericbourg, built with Hugo static site generator and deployed to GitHub Pages.

## Development Commands

All development happens in Docker containers. Use Make for convenience:

```bash
make serve    # Start dev server at http://localhost:1313
make shell    # Interactive shell with Hugo/Go
make build    # Rebuild Docker image
make clean    # Remove Docker images
```

Inside the shell:
```bash
hugo new content/posts/my-article.md   # Create new content
hugo --minify                          # Build site to /public
```

## Architecture

### Configuration Structure
- `config/_default/hugo.toml` - Main Hugo configuration
- `config/_default/languages.toml` - Language settings (FR default, EN secondary)
- `config/_default/params.toml` - Theme parameters
- `config/_default/menus.{en,fr}.toml` - Navigation menus per language

### Content Organization
Bilingual content uses suffix naming convention:
- `content/_index.fr.md` / `content/_index.en.md` - Homepage
- `content/contact.fr.md` / `content/contact.en.md` - Contact page
- `content/cv.fr.md` / `content/cv.en.md` - CV page (`layout = "cv"`, content sourced from `data/cv.yaml`)
- `content/references.fr.md` / `content/references.en.md` - References page (`layout = "references"`, content sourced from `data/references.yaml`)

Content uses TOML frontmatter with `+++` delimiters.

### Data file schemas
`data/cv.yaml` and `data/references.yaml` are validated by JSON Schemas in `schemas/`
(`cv.schema.json`, `references.schema.json`). Each data file points at its schema with a
`# yaml-language-server: $schema=../schemas/*.json` modeline on line 1 (editor completion and
validation), and `scripts/validate-data.sh` enforces the same schemas from `scripts/build.sh`
before `hugo` runs — so `make build`, `make test` and CI all fail on a malformed data file.
`make serve` runs `hugo server` directly and does *not* validate; the editor covers that.

Why it exists: most of `layouts/_default/cv.html` guards with `{{ with … }}`, so a misspelled key
renders **nothing** instead of failing. `additionalProperties: false` throughout the schemas is
what turns that silence into an error.

- **Don't move the schemas into `data/`** — Hugo loads everything there as a data file, and
  `data/cv.schema.json` would land in `hugo.Data` next to (or on top of) `cv.yaml`.
- **`spokenLanguages[].level` is duplicated in three places**: the enum in `schemas/cv.schema.json`,
  the keys of `data/cv_levels.yaml`, and the `$levelWidths` dict in `layouts/_default/cv.html`.
  Adding a level means editing all three.
- Dates are typed as **strings** on purpose: `cv.html` splits them on `-` and
  `partials/cv-format-date.html` branches on their length, so an unquoted `start: 2007` (an
  integer in YAML) breaks the build. Keep them quoted.

### Version Management
Versions are pinned in dedicated files (read by Makefile and GitHub Actions):
- `.hugo-version` - Hugo version
- `.go-version` - Go version
- `.check-jsonschema-version` - check-jsonschema version (used by `scripts/validate-data.sh`)

To update: modify the file, then `make build`.

### Theme
No external theme — `layouts/` and `assets/css/main.css` are hand-written and project-local
(no Hugo Module, no Sass/Node build step). Key files:
- `layouts/_default/baseof.html` - base template (skip link, header/main/footer scaffold)
- `layouts/partials/{head,header,footer}.html` - document head, nav + language switcher, footer
- `layouts/_default/{cv,references}.html` - data-driven layouts reading `data/cv.yaml` /
  `data/references.yaml` via `hugo.Data`
- `assets/css/main.css` - single CSS file, minified and fingerprinted at build time

## Deployment

Automatic deployment to GitHub Pages on push to `main` branch via `.github/workflows/hugo.yaml`. The workflow reads `.hugo-version` to ensure consistency between local and CI environments.

## Key Conventions

- French is the default language (`DefaultContentLanguage = "fr"`)
- No JavaScript and no webfonts — keep the site low-tech (system monospace stack, plain CSS)
- Static files go in `static/` directory
- Generated output (`public/`) is gitignored
- **Page weight**: the footer's `.page-weight` line reports **this page's own HTML bytes plus the
  bytes of the stylesheet it links** — with no JS, no webfonts and no images, that is the whole
  page. Hugo cannot compute it (a page has no way to know its own final size while it is still
  being rendered), so `layouts/partials/footer.html` renders a `~?` placeholder and
  `scripts/page-weight.py` replaces it with the measured value, from `scripts/build.sh` right
  after `hugo --gc --minify`. Consequences: `make serve` shows `~?`, which is correct — the number
  only exists in a built `public/`. The script keys off the `page-weight` class (also used by
  `assets/css/main.css`) and **exits non-zero if it matches no page**, so renaming that class or
  dropping the `~` from the sentence breaks the build instead of silently shipping a stale figure.
  It reads the CSS size from each page's own `<link rel="stylesheet">` rather than globbing
  `public/css/main.min.*.css`, because Hugo does not clear `public/` and a glob can hit a stale
  fingerprinted bundle. Nothing here is hand-calibrated — if you find yourself adding a constant to
  make the dev server show a number, don't: that is the bug this replaced. The figure is
  uncompressed bytes (GitHub Pages serves it gzipped, so the wire cost is roughly a quarter), and
  it never appears in the CV PDFs because `@media print` hides `.site-footer`. `scripts/test-page-weight.sh`
  (`make test`) guards this: it fails if the figure is constant across pages or drifts from the
  real file size by more than 50 bytes

## SEO / GEO

- `layouts/partials/schema-person.html` emits Person JSON-LD (home + CV pages only), built entirely from `data/cv.yaml` and `site.Params.socialLinks` — don't hand-edit facts into it, edit the CV data instead
- `layouts/robots.txt` explicitly allows named AI crawlers (GPTBot, ClaudeBot, PerplexityBot, Google-Extended, etc.) in addition to `User-agent: *` — a named group overrides the wildcard rather than adding to it, so each one repeats `Allow: /` in full
- `static/llms.txt` is generated (`layouts/index.llms.txt`, output format `llms` on the home page) — don't recreate a hand-written `static/llms.txt`, it will shadow the generated one
- **`lastmod` convention**: `enableGitInfo = true` derives each page's sitemap `<lastmod>` from git history of its `content/*.md` file. The CV and references pages render from `data/cv.yaml` / `data/references.yaml`, which Hugo doesn't track for this purpose — when editing those YAML files, **set `lastmod = YYYY-MM-DD` in the matching `content/cv.*.md` / `content/references.*.md` front matter in the same commit**, or the sitemap date won't move. This works only because `[frontmatter] lastmod = ["lastmod", ":git", ":default"]` in `hugo.toml` puts front matter ahead of the git date — with `enableGitInfo` alone, `:git` wins and an explicit `lastmod` is silently ignored. Note the flip side: once a page has an explicit `lastmod`, git changes no longer move it, so that date must be bumped by hand on every subsequent content change to those pages
- **OG cards**: `design/og-card.{fr,en}.svg` are the source; `static/og-card.{fr,en}.png` (1200×630) are committed, generated output. After editing the SVGs, regenerate with `sh scripts/og-cards.sh` (requires `rsvg-convert` locally — not part of `make build`, since the cards change essentially never) and commit the new PNGs
- **Person `@id`**: `layouts/partials/schema-person.html` gives the Person node a stable `@id` (the default-language home permalink + `#person`), computed independently of the current page's language so it stays byte-identical across `/`, `/cv/`, `/en/`, `/en/cv/`. This is what lets crawlers treat those four pages as one entity described four times rather than four unrelated people — never derive it from `site.BaseURL` or `.Permalink` (both are language-scoped) and never let it vary per page
- **IndexNow key**: `static/eb8cf8b7c4ec261dd3665cd45b8b8bec.txt` is the public IndexNow key, referenced by name in the `notify` job in `.github/workflows/hugo.yaml`. It's not a secret — but renaming, moving, or deleting the file silently breaks the ping (IndexNow validates the key by fetching `https://dericbourg.dev/<key>.txt`), so if it ever needs rotating, update both the file and the workflow's `INDEXNOW_KEY` together

## Accessibility (WCAG 2.2 AA)

Target compliance: **WCAG 2.2 Level AA**. All changes must maintain or improve accessibility.

### Requirements for New Content
- All images must have meaningful `alt` text (or `alt=""` if purely decorative)
- Links must have descriptive text (avoid "click here", "read more")
- External links should indicate they open in a new tab
- Maintain proper heading hierarchy (h1 → h2 → h3, no skipped levels)
- Content in both languages must be semantically equivalent

### Requirements for CSS/Styling Changes
- Text contrast ratio: minimum 4.5:1 (3:1 for large text ≥18pt)
- UI component contrast: minimum 3:1
- Never remove focus outlines (`outline: none`) without providing visible alternative
- Include `@media (prefers-reduced-motion: reduce)` for animations
- Test in both light and dark themes

### Requirements for Interactive Elements
- All interactive elements must be keyboard accessible
- Focus order must follow visual order
- Custom widgets need proper ARIA roles, states, and keyboard handlers
- Language switcher must work with keyboard alone
