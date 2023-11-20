render_icons() {
  # Input comes from the final card structure
  jq '.content.chapters | map(.tracks[0].display.icon16x16 | sub("^yoto:#"; "")) | sort | unique | { icons: map({ mediaId: . }) }'
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
      "icon16x16": ("yoto:#" + $icon)
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
