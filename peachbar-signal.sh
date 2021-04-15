#!/bin/sh

# Alert peachbar to update

test -z "$1" && exit 0

SPID="$(cat "/tmp/peachbar-Module$1.fifo")"
kill "$SPID"
