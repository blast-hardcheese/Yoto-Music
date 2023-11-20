m4a() {
  slug="$1"; shift || die 'Missing file'
  target="$1"; shift || die 'Missing target'

  existing=( "$target"/*"-$slug.m4a" )
  if [ -z "$DOWNLOAD_ANYWAY" ] && [ -e "${existing[0]}" ]; then
    status "Found ${existing[0]}"
  elif [ -n "$slug" ]; then
    download "$slug" "$target"
    existing=( "$target"/*"-$slug.m4a" )
  fi
  echo "$existing"
}

thumbnail() {
  slug="$1"; shift || die 'Missing file'
  target="$1"; shift || die 'Missing target'

  yoto=( "$target"/*"-$slug-yoto.png" )
  if [ -f "${yoto}" ]; then
    status "Found ${yoto}, skipping"
  else
    for src in "$target"/*"-$slug."{webp,png,jpg}; do
      [ -f "$src" ] || continue
      dest="$target/$(basename "${src%.*}-yoto.png")"
      status "Converting $src into $dest"
      convert "$src" -resize 16x16^ -gravity Center -extent 16x16 "$dest" && break
    done
    yoto=( "$target"/*"-$slug-yoto.png" )
  fi
  echo "$yoto"
}

_info() {
  slug="$1"; shift || die 'Missing file'
  target="$1"; shift || die 'Missing target'

  existing=( "$target"/*"-$slug.info.json" )
  if [ -z "$DOWNLOAD_ANYWAY" ] && [ -e "${existing[0]}" ]; then
    status "Found ${existing[0]}"
  elif [ -n "$slug" ]; then
    download "$slug" "$target"
    existing=( "$target"/*"-$slug.info.json" )
  fi
  echo "$existing"
}

download() {
  slug="$1"; shift || die 'Missing file'
  target="$1"; shift || die 'Missing target'
  (cd "$target"; youtube-dl -f m4a --write-info-json --write-thumbnail "https://youtu.be/$slug" >&2)
}
