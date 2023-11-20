die() {
  echo "ERROR: $@" >&2
  exit 1
}

status() {
  echo "$@" >&2
}

strip_slug() {
  slug="$1"; shift || die 'Missing slug'
  read input
  ext="${input##*.}"
  prefix="${input%-$slug*}"
  echo "$prefix.$ext"
}

urlencode() {
  python <<!
from urllib import parse

import sys

for line in sys.stdin.readlines():
  print(parse.quote_plus(line.strip()))
!
}

websha() {
  file="$1"; shift || die 'Missing file'
  sha256sum -b "$file" \
    | xxd -r -p \
    | base64 \
    | sed 's/\+/-/g; s/\//_/g; s/=*$//'
}
