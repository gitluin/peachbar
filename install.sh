#!/bin/sh

SCRIPTFILES="$(ls | grep '.sh')"

for SCRIPT in $SCRIPTFILES; do
	ln -s $SCRIPT /usr/local/bin/
done

mkdir -p $HOME/.config/peachbar/
cp peachbar.conf $HOME/.config/peachbar/
