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

persist_icons() {
  status -n 'Persisting icons...'
  res="$(api 'media/user/icons' \
    -H 'Content-Type: application/json' \
    --data @-)"
  status ' Done.'
}


persist_content() {
  status -n 'Persisting content...'
  content="$(api 'content' \
    -H 'content-type: application/json;charset=UTF-8' \
    --data @-)"
  status ' Done.'
}

# Examples:
# card "$(cards | jq -r '.cards[0].cardId')"
# my_icons
# upload "./tracks/19-Cherokee Bend.m4a"
# upload_icon "./tracks/16-yoto-Renegade.png"
