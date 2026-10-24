#!/bin/bash
# Apply the platform patches to a LineageOS-UL 21.0 tree. Run from the tree root after `repo sync`.
# Checks every project first and changes nothing unless all are at the commit their patches were made on.
set -euo pipefail
P="$(cd "$(dirname "$0")" && pwd)"
series() { grep -v '^#' "$P/SERIES.tsv" | grep -v '^$'; }

bad=0
while IFS=$'\t' read -r path base _; do
  head=$(git -C "$path" rev-parse HEAD)
  [ "$head" = "$base" ] || { echo "$path is at ${head:0:12}, the patches were made on ${base:0:12}" >&2; bad=1; }
done < <(series)
if [ $bad = 1 ] && [ -z "${FORCE:-}" ]; then
  echo "Nothing applied. Sync with pinned-manifest.xml, or set FORCE=1 to try anyway." >&2
  exit 1
fi

while IFS=$'\t' read -r path _ _; do
  git -C "$path" am -q --3way "$P/patches/$path"/*.patch
  echo "applied $path"
done < <(series)
