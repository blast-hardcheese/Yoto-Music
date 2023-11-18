#!/usr/bin/env bash

last=$(pbpaste)

while true; do
  if [ "$last" != "$next" ]; then
    echo "$next" | tee -a links.txt
    last="$next"
  fi
  next=$(pbpaste)
  sleep 0.5
done
