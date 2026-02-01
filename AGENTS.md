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
- `content/about.fr.md` / `content/about.en.md` - About page

Content uses TOML frontmatter with `+++` delimiters.

### Version Management
Versions are pinned in dedicated files (read by Makefile and GitHub Actions):
- `.hugo-version` - Hugo version
- `.go-version` - Go version

To update: modify the file, then `make build`.

### Theme
Uses [Anatole](https://github.com/lxndrblz/anatole) theme as a Hugo Module (defined in `go.mod`).

## Deployment

Automatic deployment to GitHub Pages on push to `main` branch via `.github/workflows/hugo.yaml`. The workflow reads `.hugo-version` to ensure consistency between local and CI environments.

## Key Conventions

- French is the default language (`DefaultContentLanguage = "fr"`)
- LaTeX math supported via passthrough delimiters (`$$...$$` for blocks, `\(...\)` for inline)
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
- Theme/language switchers must work with keyboard alone

### Known Issues to Address
- Missing skip-to-content link
- Theme switcher not keyboard accessible (upstream theme issue)
- Some low-contrast secondary text (#9f9f9f)
- Empty `<h1>` on content pages (theme template issue)
