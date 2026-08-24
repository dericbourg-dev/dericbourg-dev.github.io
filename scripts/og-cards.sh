#!/usr/bin/env sh
set -eu

# Regenerates the Open Graph / Twitter share-card PNGs from their SVG sources.
# Manual, one-off step — NOT part of `make build`. The cards change roughly
# never, so a rasterizer (rsvg-convert) isn't worth adding to the build image.
# Run this locally after editing design/og-card.*.svg, then commit the PNGs.

for lang in fr en; do
  rsvg-convert -w 1200 -h 630 "design/og-card.${lang}.svg" -o "static/og-card.${lang}.png"
done
