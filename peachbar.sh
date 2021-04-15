#!/bin/sh

if test -f "$HOME/.config/peachbar/peachbar.conf"; then
	. "$HOME/.config/peachbar/peachbar.conf"
else
	echo "Missing config file: $HOME/.config/peachbar/peachbar.conf"
	exit -1
fi

# Clear out any stale fifos
test -e "$PEACHFIFO" && ! test -p "$PEACHFIFO" && sudo rm "$PEACHFIFO"
test -p "$PEACHFIFO" || sudo mkfifo -m 777 "$PEACHFIFO"

# Set the number of clickable areas based on the number of tags, monitors,
#	number of modules, and the layout symbol.
# Every module defaults to getting 2 clickables
NUMTAGS="$(echo -e $(echo $TAGS | sed 's/:/\\n/g') | wc -l)"
test -z "$NUMCLICKPERMOD" && NUMCLICKPERMOD=2
NUMMOD="$(echo -e $(echo $MODULES | sed 's/ /\\n/g') | wc -l)"
NUMMON="$(xrandr -q | grep ' connected' | wc -l)"
NUMFIELDS="$(($NUMTAGS + $(($NUMMOD * $NUMCLICKPERMOD)) + 1))"
NUMCLICK="$(($NUMFIELDS * $NUMMON))"

peachbar-sys.sh < "$PEACHFIFO" | lemonbar \
	-a $NUMCLICK \
	-g "$BARW"x"$BARH"+"$BARX"+"$BARY" \
	-d \
	-f "$BARFONT" -f "$ICONFONT" \
	-B "$BARBG" -F "$BARFG" \
	| sh &
