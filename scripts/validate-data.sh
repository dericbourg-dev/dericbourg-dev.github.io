#!/usr/bin/env sh
set -eu

# Validates the hand-edited data files against their JSON Schemas.
#
# The schemas in schemas/ are also referenced by a `# yaml-language-server:`
# modeline at the top of each data file, so the editor and the build enforce the
# same rules. Run before Hugo (from scripts/build.sh): most of the CV template
# guards with `{{ with … }}`, so a misspelled key renders nothing rather than
# failing the build — the schema is what turns that silence into an error.

[ -f config/_default/hugo.toml ] || {
  echo "validate-data: run from the repository root" >&2
  exit 1
}

check-jsonschema --schemafile schemas/cv.schema.json         data/cv.yaml
check-jsonschema --schemafile schemas/references.schema.json data/references.yaml
