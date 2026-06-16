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

### Version Management
Versions are pinned in dedicated files (read by Makefile and GitHub Actions):
- `.hugo-version` - Hugo version
- `.go-version` - Go version

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
