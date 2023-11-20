#!/usr/bin/env bash

set -e

if [ -e .env ]; then
  source ".env"
fi

source "lib/api.sh"
source "lib/download.sh"
source "lib/render.sh"
source "lib/utils.sh"

render_tracks() {
  file="$1"; shift || die 'Missing file'
  target="$1"; shift || die 'Missing target'

  track=1
  cat "$file" | while read link; do
    slug="$(echo "$link" | grep -ho 'v=[a-zA-Z0-9_-]*' | sed 's/^v=//')"
    [ -n "$slug" ] || continue

    status "Processing $track: $link..."

    audio_file="$(m4a "$slug" "$target")"
    icon_file="$(thumbnail "$slug" "$target")"
    info_file="$(_info "$slug" "$target")"

    title="$(cat "$info_file" | jq -r .title)"

    icon="$(upload_icon "$icon_file" | jq -r .displayIcon.mediaId)"

    upload_info="$(upload "$audio_file")"
    echo "$upload_info" >&2
    if [ -n "$upload_info" ]; then
      echo "$upload_info" | render_track "$title" "$track" "$icon"
    fi
    track=$((track + 1))
  done | jq -sc .
  status "Done."
}

main() {
  file="$1"; shift || die 'Missing file'
  target="$1"; shift || die 'Missing target'
  cardId="$1"; shift || die 'Missing cardId'
  title="$1"; shift || die 'Missing title'

  if [ -n "$CACHE" ] && [ -f "$CACHE" ]; then
    content="$(cat "$CACHE")"
  else
    tracks="$(render_tracks "$file" "$target")"
    content="$(render_content_template "$cardId" "$title" | jq --argjson tracks "$tracks" '.content.chapters |= $tracks')"
    if [ -n "$CACHE" ]; then
      echo "$content" > "$CACHE"
    fi
  fi

  echo "$content" | render_icons | persist_icons
  echo "$content" | persist_content
}

main "$@"
