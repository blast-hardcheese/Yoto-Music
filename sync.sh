#!/usr/bin/env bash

set -e

if [ -e .env ]; then
  source ".env"
fi

source "lib/api.sh"
source "lib/download.sh"
source "lib/render.sh"
source "lib/utils.sh"

persist() {
  cardId="$1"; shift || die 'Missing cardId'

  if [ -n "$CACHE" ] && [ -f "$CACHE" ]; then
    content="$(cat "$CACHE")"
  else
    tracks="$(render_tracks)"
    content="$(render_content_template "$cardId" | jq --argjson tracks "$tracks" '.content.chapters |= $tracks')"
    if [ -n "$CACHE" ]; then
      echo "$content" > "$CACHE"
    fi
  fi

  echo "$content" | render_icons | persist_icons
  echo "$content" | persist_content
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

main() {
  cardId="$1"; shift || die 'Missing cardId'

  persist "$cardId"
}

main "$@"
