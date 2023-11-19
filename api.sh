#!/usr/bin/env bash

set -e

if [ -e .env ]; then
  source ".env"
fi

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

upload() {
  # This doesn't work. File uploads are done in the browser by way of a mechanism that doesn't report in the Network panel.
  # api 'media/transcode/audio/uploadUrl?sha256=...&filename=...' --data @track/...
  return
}

# card "$(cards | jq -r '.cards[0].cardId')"
# my_icons
# upload
