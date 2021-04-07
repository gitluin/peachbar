#!/bin/sh

SARAFIFO="$1"
PEACHFIFO="$2"

sara > $SARAFIFO &

# from gitlab.com/mellok1488/dotfiles/panel
trap 'trap - TERM; kill 0' INT TERM QUIT EXIT

while read line; do
	echo "$line" > $SARAFIFO
	echo "sara" > $PEACHFIFO
done < $SARAFIFO
