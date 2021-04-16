#!/bin/sh

# Alert peachbar to update

test -z "$1" && exit 0

SPID="$(cat "/tmp/peachbar-Module$1.timerid")"
rm "/tmp/peachbar-Module$1.timerid"
kill "$SPID"
