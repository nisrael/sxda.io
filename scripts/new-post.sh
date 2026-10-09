#!/usr/bin/env bash
set -euo pipefail

read -rp "Title: " title
[ -n "$title" ] || { echo "Title must not be empty" >&2; exit 1; }

slug=$(echo "$title" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g')
date=$(date +%Y-%m-%dT%H:%M:%S%:z)
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
post_path="$repo_root/content/posts/$slug.md"

if [ -e "$post_path" ]; then
  echo "Refusing to overwrite existing file: $post_path" >&2
  exit 1
fi

cat > "$post_path" <<EOF
+++
title = "$title"
date = $date

[taxonomies]
categories = []
tags = []
+++

EOF

echo "Created $post_path"
