#!/usr/bin/env bash

set -e

if [ -e .env ]; then
  source ".env"
fi

source "lib/api.sh"
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

main() {
  cardId="$1"; shift || die 'Missing cardId'

  persist "$cardId"
}

main "$@"
