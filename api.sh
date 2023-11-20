#!/usr/bin/env bash

set -e

if [ -e .env ]; then
  source ".env"
fi

die() {
  echo "ERROR: $@" >&2
  exit 1
}

status() {
  echo "$@" >&2
}

urlencode() {
  python <<!
from urllib import parse

import sys

for line in sys.stdin.readlines():
  print(parse.quote_plus(line.strip()))
!
}

api() {
  path="$1"; shift || die 'Missing path'
  curl -s 'https://api.yotoplay.com/'"$path" \
    -H 'authority: api.yotoplay.com' \
    -H 'accept: application/json, text/plain, */*' \
    -H 'accept-language: en-US,en;q=0.9' \
    -H "authorization: Bearer $YOTO_SESSION_TOKEN" \
    -H 'origin: https://my.yotoplay.com' \
    -H 'referer: https://my.yotoplay.com/' \
    -H 'sec-ch-ua: "Brave";v="113", "Chromium";v="113", "Not-A.Brand";v="24"' \
    -H 'sec-ch-ua-mobile: ?0' \
    -H 'sec-ch-ua-platform: "macOS"' \
    -H 'sec-fetch-dest: empty' \
    -H 'sec-fetch-mode: cors' \
    -H 'sec-fetch-site: same-site' \
    -H 'sec-gpc: 1' \
    -H 'user-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/113.0.0.0 Safari/537.36' \
    --compressed \
    "$@"
}

cards() {
  api 'card/mine'
}

card() {
  id="$1"; shift || die 'Missing card ID'
  api "content/$id"
}

my_icons() {
  api 'media/displayIcons/user/me'
}

upload_icon() {
  file="$1"; shift || die 'Missing file'
  api 'media/displayIcons/user/me/upload' \
    -H 'content-type: image/png' \
    --data-binary @"$file"
}

delete_icon() {
  icon_id="$1"; shift || die 'Missing icon_id'
  api "media/displayIcon/$icon_id" \
  -X 'DELETE'
}

websha() {
  file="$1"; shift || die 'Missing file'
  sha256sum -b "$file" \
    | xxd -r -p \
    | base64 \
    | sed 's/\+/-/g; s/\//_/g; s/=*$//'
}

transcoded() {
  sha="$1"; shift || die 'Missing sha'
  api "media/upload/${sha}/transcoded?loudnorm=false"
}

upload() {
  file="$1"; shift || die 'Missing file'
  sha="$(websha "$file")"
  fname="$(basename "$file" | urlencode)"
  upload_url=$(api "media/transcode/audio/uploadUrl?sha256=${sha}&filename=${fname}" | jq -r '.upload.uploadUrl // ""')

  if [ -n "$upload_url" ]; then
    status -n "Uploading..."
    _upload "$upload_url" "$file"
    status " Done!"

    transcoded_sha=
    status -n "Transcoding..."
    while [ -z "$transcoded_sha" ]; do
      transcoded_sha="$(transcoded "$sha" | jq -r '.transcode // ""')"
      status -n .
      sleep 2
    done
    status " Done!"
  else
    transcoded_sha="$(transcoded "$sha" | jq -r '.transcode // ""')"
  fi
  echo "$transcoded_sha"
}

_upload() {
  upload_url="$1"; shift || die 'Missing upload_url'
  file="$1"; shift || die 'Missing file'
  curl -s "$upload_url" \
    -X 'PUT' \
    -H 'Accept: application/json, text/plain, */*' \
    -H 'Accept-Language: en-US,en;q=0.9,ja;q=0.8' \
    -H 'Connection: keep-alive' \
    -H 'DNT: 1' \
    -H 'Origin: https://my.yotoplay.com' \
    -H 'Referer: https://my.yotoplay.com/' \
    -H 'Sec-Fetch-Dest: empty' \
    -H 'Sec-Fetch-Mode: cors' \
    -H 'Sec-Fetch-Site: cross-site' \
    -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36' \
    -H 'sec-ch-ua: "Google Chrome";v="119", "Chromium";v="119", "Not?A_Brand";v="24"' \
    -H 'sec-ch-ua-mobile: ?0' \
    -H 'sec-ch-ua-platform: "macOS"' \
    -H 'Content-Type: application/x-www-form-urlencoded' \
    --data-binary @"$file"
}

render_icons() {
  # Input comes from the final card structure
  jq '.content.chapters | map(.tracks[0].display.icon16x16 | sub("^yoto:#"; "")) | sort | unique | { icons: map({ mediaId: . }) }'
}

persist_icons() {
  status -n 'Persisting icons...'
  res="$(api 'media/user/icons' \
    -H 'Content-Type: application/json' \
    --data @-)"
  status ' Done.'
}

render_track() {
  title="$1"; shift || die 'Missing title'
  track="$1"; shift || die 'Missing track'
  icon="$1"; shift || die 'Missing icon'
  key="$(printf "%02d" "$((track-1))")"

  jq \
    --arg key "$key" \
    --arg title "$title" \
    --arg track "$track" \
    --arg icon "$icon" \
    '
  {
    "key": $key,
    "title": $title,
    "overlayLabel": "1",
    "tracks": [
      {
        "key": "01",
        title: $title,
        format: .transcodedInfo.format,
        "trackUrl": ("yoto:#" + .transcodedSha256),
        "type": "audio",
        "overlayLabel": $track,
        "display": {
          "icon16x16": ("yoto:#" + $icon)
        },
        "duration": .transcodedInfo.duration,
        "fileSize": .transcodedInfo.fileSize,
        "channels": .transcodedInfo.channels
      }
    ],
    "display": {
      "icon16x16": "yoto:#..."
    }
  }
'
}


render_content_template() {
  cardId="$1"; shift || die 'Missing cardId'

  cat <<!
{
  "title": "Classic Rock (Test)",
  "content": {
    "activity": "yoto_Player",
    "chapters": [
    ],
    "restricted": true,
    "config": {
      "onlineOnly": false
    },
    "version": "1",
    "editSettings": {}
  },
  "metadata": {
    "cover": {
      "imageL": "https://cdn.yoto.io/myo-cover/star_grapefruit.gif"
    },
    "media": {
      "fileSize": 8287388,
      "duration": 510,
      "readableDuration": "0h 8m 30s",
      "readableFileSize": 7.9,
      "hasStreams": false
    }
  },
  "cardId": "${cardId}",
  "userId": "${YOTO_USER_ID}",
  "createdAt": "2023-11-20T04:59:25.955Z",
  "updatedAt": "2023-11-20T05:06:21.759Z"
}
!
}

render_tracks() {
  track=0
  for file in tracks/*.m4a; do
    status "Processing $file..."
    title="${file%.m4a}"
    title="${title#*-}"
    icon_file="${file%.m4a}.png"
    icon="$(upload_icon "$icon_file" | jq -r .displayIcon.mediaId)"

    track=$((track + 1))
    upload "$file" | render_track "$title" "$track" "$icon"
  done | jq -sc .
  status "Done."
}

persist_content() {
  status -n 'Persisting content...'
  content="$(api 'content' \
    -H 'content-type: application/json;charset=UTF-8' \
    --data @-)"
  status ' Done.'
}

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

# card "$(cards | jq -r '.cards[0].cardId')"
# my_icons
# upload "./tracks/19-Cherokee Bend.m4a"
# upload_icon "./tracks/16-yoto-Renegade.png"

persist "$@"
