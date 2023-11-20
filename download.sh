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

  yoto=( "$target"/*"-$slug-yoto.png" )
  if [ -f "${yoto}" ]; then
    echo "Found ${yoto}, skipping"
  else
    for src in "$target"/*"-$slug."{webp,png,jpg}; do
      [ -f "$src" ] || continue
      dest="$target/$(basename "${src%.*}-yoto.png")"
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

strip_slug() {
  slug="$1"; shift || die 'Missing file'
  read input
  ext="${input##*.}"
  prefix="${input%-$slug*}"
  echo "$prefix.$ext"
}

track() {
  number="$1"; shift || die 'Missing track number'
  tracks="$1"; shift || die 'Missing tracks directory'
  slug="$1"; shift || die 'Missing file'
  target="$1"; shift || die 'Missing target'

  number="$(printf %02d "$number")"
  m4a=( "$target"/*"-$slug.m4a" )
  yoto=( "$target"/*"-$slug-yoto.png" )

  [ -f "$m4a" ] && [ -f "$yoto" ] || die "Missing one of $m4a or $yoto for $slug"

  ln "$m4a" "$tracks/$number-$(basename "$m4a" | strip_slug "$slug")"
  ln "$yoto" "$tracks/$number-$(basename "$yoto" | strip_slug "$slug")"
}

main() {
  file="$1"; shift || die 'Missing file'
  target="$1"; shift || die 'Missing target'
  tracks="$1"; shift || die 'Missing tracks'

  idx=1
  cat "$file" | while read link; do
    slug="$(echo "$link" | grep -ho 'v=[a-zA-Z0-9_-]*' | sed 's/^v=//')"
    [ -n "$slug" ] || continue
    m4a "$slug" "$target"
    thumbnail "$slug" "$target"
    track "$idx" "$tracks" "$slug" "$target"
    idx=$((idx+1))
  done
}

main "$@"
