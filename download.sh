#!/usr/bin/env bash

set -e

m4a() {
  slug="$1"; shift || die 'Missing file'
  target="$1"; shift || die 'Missing target'

  existing=( "$target"/*"-$slug.m4a" )
  if [ -e "${existing[0]}" ]; then
    echo "Found ${existing[0]}"
  elif [ -n "$slug" ]; then
    download "$slug" "$target"
  fi
}

thumbnail() {
  echo "THUMBNAIL $@" >&2
  slug="$1"; shift || die 'Missing file'
  target="$1"; shift || die 'Missing target'

  yoto=( "$target"/yoto-*"-$slug.png" )
  if [ -f "${yoto}" ]; then
    echo "Found ${yoto}, skipping"
  else
    for src in "$target"/*"-$slug."{webp,png,jpg}; do
      [ -f "$src" ] || continue
      dest="$target/yoto-$(basename "${src%.*}.png")"
      echo "Converting $src into $dest"
      convert "$src" -resize 16x16^ -gravity Center -extent 16x16 "$dest" && break
    done
  fi
}

download() {
  slug="$1"; shift || die 'Missing file'
  target="$1"; shift || die 'Missing target'
  (cd "$target"; youtube-dl -f m4a --write-thumbnail "https://youtu.be/$slug")
}

main() {
  file="$1"; shift || die 'Missing file'
  target="$1"; shift || die 'Missing target'

  cat "$file" | while read link; do
    slug="$(echo "$link" | grep -ho 'v=[a-zA-Z0-9_-]*' | sed 's/^v=//')"
    [ -n "$slug" ] || continue
    m4a "$slug" "$target"
    thumbnail "$slug" "$target"

  done
}

main "$@"
